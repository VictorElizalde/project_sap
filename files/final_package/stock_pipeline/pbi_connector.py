"""
pbi_connector.py
================
Handles all Power BI REST API interactions:
  - Azure AD authentication (service principal)
  - Dataset creation / schema management
  - Pushing rows in batches
  - Triggering scheduled refresh

Cline: if push fails, common issues are:
  - App not registered in Azure → see docs/AZURE_SETUP.md
  - App not added to Power BI workspace as Member → workspace settings in app.powerbi.com
  - Dataset ID wrong → let pipeline create it fresh (leave dataset IDs blank in settings)
  - Row limit exceeded → batch_size is set to 9000 in settings (API limit is 10,000)

API reference: https://learn.microsoft.com/en-us/rest/api/power-bi/
"""

import logging
import time
from typing import Optional

import pandas as pd
import requests

log = logging.getLogger(__name__)

# ── Power BI API base URL ─────────────────────────────────────────────────────
PBI_BASE = "https://api.powerbi.com/v1.0/myorg"


class PowerBIConnector:
    def __init__(self, settings):
        self.settings = settings
        self._token: Optional[str] = None
        self._token_expiry: float = 0

    # ── Authentication ─────────────────────────────────────────────────────────
    def get_token(self) -> str:
        """Get Azure AD token for Power BI. Auto-refreshes when expired."""
        if self._token and time.time() < self._token_expiry - 60:
            return self._token

        log.info("Authenticating with Azure AD (tenant: %s)", self.settings.tenant_id[:8] + "...")

        url = f"https://login.microsoftonline.com/{self.settings.tenant_id}/oauth2/v2.0/token"
        payload = {
            "grant_type":    "client_credentials",
            "client_id":     self.settings.client_id,
            "client_secret": self.settings.client_secret,
            "scope":         "https://analysis.windows.net/powerbi/api/.default",
        }

        resp = requests.post(url, data=payload, timeout=30)

        if resp.status_code != 200:
            raise ConnectionError(
                f"Azure AD authentication failed (HTTP {resp.status_code})\n"
                f"Response: {resp.text}\n\n"
                f"Common fixes:\n"
                f"  1. Verify tenant_id, client_id, client_secret in config/settings.py\n"
                f"  2. Check the app has 'Dataset.ReadWrite.All' API permission in Azure\n"
                f"  3. Make sure admin consent was granted for the permission\n"
                f"  4. See docs/AZURE_SETUP.md for full setup steps"
            )

        data = resp.json()
        self._token = data["access_token"]
        self._token_expiry = time.time() + data.get("expires_in", 3600)
        log.info("Azure AD authentication successful")
        return self._token

    def _headers(self) -> dict:
        return {
            "Authorization": f"Bearer {self.get_token()}",
            "Content-Type":  "application/json",
        }

    def _api(self, method: str, path: str, **kwargs) -> requests.Response:
        """Make a Power BI REST API call with automatic retry on 429 (rate limit)."""
        url = f"{PBI_BASE}/{path}"
        for attempt in range(1, 4):
            resp = getattr(requests, method)(url, headers=self._headers(), timeout=60, **kwargs)

            if resp.status_code == 429:
                wait = int(resp.headers.get("Retry-After", 30))
                log.warning("Rate limited — waiting %ds (attempt %d/3)", wait, attempt)
                time.sleep(wait)
                continue

            return resp

        raise RuntimeError(f"API call failed after 3 retries: {method.upper()} {path}")

    def test_connection(self):
        resp = self._api("get", f"groups/{self.settings.workspace_id}/datasets")
        if resp.status_code != 200:
            raise ConnectionError(
                f"Power BI connection failed (HTTP {resp.status_code})\n"
                f"Response: {resp.text}\n\n"
                f"Common fixes:\n"
                f"  1. Confirm workspace_id is correct (check the URL in app.powerbi.com)\n"
                f"  2. Add the app as Member to the workspace:\n"
                f"     Workspace → Settings → Access → add client_id as Member"
            )
        datasets = resp.json().get("value", [])
        log.info("Power BI connection OK — workspace has %d datasets", len(datasets))
        return True

    # ── Dataset management ─────────────────────────────────────────────────────
    def get_or_create_dataset(self, name: str, df: pd.DataFrame) -> str:
        """
        Check if a dataset exists by name. If not, create it from the DataFrame schema.
        Returns the dataset ID.
        """
        # Check existing datasets
        resp = self._api("get", f"groups/{self.settings.workspace_id}/datasets")
        resp.raise_for_status()
        existing = {d["name"]: d["id"] for d in resp.json().get("value", [])}

        if name in existing:
            log.info("Dataset '%s' already exists (id: %s)", name, existing[name])
            return existing[name]

        # Create new dataset
        log.info("Creating new Power BI dataset: %s", name)
        schema = self._df_to_pbi_schema(name, df)

        resp = self._api(
            "post",
            f"groups/{self.settings.workspace_id}/datasets?defaultRetentionPolicy=basicFIFO",
            json=schema
        )

        if resp.status_code not in (200, 201):
            raise RuntimeError(
                f"Failed to create dataset '{name}' (HTTP {resp.status_code})\n{resp.text}"
            )

        dataset_id = resp.json()["id"]
        log.info("Dataset '%s' created — id: %s", name, dataset_id)
        log.info("  → Add this to config/settings.py: datasets[\"%s\"] = \"%s\"", name, dataset_id)
        return dataset_id

    def _df_to_pbi_schema(self, dataset_name: str, df: pd.DataFrame) -> dict:
        """Convert a pandas DataFrame schema to Power BI dataset definition."""
        TYPE_MAP = {
            "int64":          "Int64",
            "int32":          "Int64",
            "float64":        "Double",
            "float32":        "Double",
            "bool":           "Boolean",
            "datetime64[ns]": "DateTime",
            "object":         "String",
        }

        columns = []
        for col in df.columns:
            dtype = str(df[col].dtype)
            pbi_type = TYPE_MAP.get(dtype, "String")
            columns.append({"name": col, "dataType": pbi_type})

        return {
            "name": dataset_name,
            "defaultMode": "Push",
            "tables": [
                {
                    "name": dataset_name,
                    "columns": columns,
                }
            ],
        }

    def clear_table(self, dataset_id: str, table_name: str):
        """Delete all rows from a Push dataset table before re-pushing."""
        log.info("Clearing table '%s' in dataset %s ...", table_name, dataset_id[:8])
        resp = self._api(
            "delete",
            f"groups/{self.settings.workspace_id}/datasets/{dataset_id}/tables/{table_name}/rows"
        )
        if resp.status_code not in (200, 204):
            log.warning("Clear table returned HTTP %s — may already be empty", resp.status_code)

    # ── Data push ─────────────────────────────────────────────────────────────
    def push_dataframe(self, dataset_id: str, table_name: str, df: pd.DataFrame, batch_size: int = 9000):
        """
        Push a pandas DataFrame to a Power BI Push dataset in batches.
        Power BI REST API limit: 10,000 rows per request.
        """
        total = len(df)
        log.info("Pushing %d rows to '%s' in %d batches ...", total, table_name, -(-total // batch_size))

        # Sanitize: convert timestamps to ISO strings, NaN → None
        df = df.copy()
        for col in df.select_dtypes(include=["datetime64[ns]", "datetime64"]).columns:
            df[col] = df[col].dt.strftime("%Y-%m-%dT%H:%M:%S").where(df[col].notna(), None)
        df = df.where(pd.notna(df), None)

        pushed = 0
        for i in range(0, total, batch_size):
            batch = df.iloc[i : i + batch_size]
            rows  = batch.to_dict(orient="records")

            resp = self._api(
                "post",
                f"groups/{self.settings.workspace_id}/datasets/{dataset_id}/tables/{table_name}/rows",
                json={"rows": rows},
            )

            if resp.status_code not in (200, 201):
                raise RuntimeError(
                    f"Push failed at batch {i//batch_size + 1} "
                    f"(HTTP {resp.status_code})\n{resp.text}"
                )

            pushed += len(batch)
            log.info("  Pushed %d / %d rows", pushed, total)

        log.info("Push complete: %d rows → '%s'", total, table_name)

    # ── Refresh ───────────────────────────────────────────────────────────────
    def trigger_refresh(self, dataset_id: str):
        """Trigger an on-demand refresh of a Power BI dataset."""
        log.info("Triggering refresh for dataset %s ...", dataset_id[:8])
        resp = self._api(
            "post",
            f"groups/{self.settings.workspace_id}/datasets/{dataset_id}/refreshes",
            json={"notifyOption": "MailOnFailure"},
        )
        if resp.status_code in (200, 202):
            log.info("Refresh triggered successfully")
        else:
            log.warning("Refresh trigger returned HTTP %s: %s", resp.status_code, resp.text)

    def get_refresh_status(self, dataset_id: str) -> dict:
        """Check the status of the last refresh."""
        resp = self._api(
            "get",
            f"groups/{self.settings.workspace_id}/datasets/{dataset_id}/refreshes?$top=1"
        )
        resp.raise_for_status()
        history = resp.json().get("value", [])
        return history[0] if history else {}
