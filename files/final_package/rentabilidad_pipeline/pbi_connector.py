"""
pbi_connector.py — Power BI REST API connector.
Cline: auth errors → check PBI_TENANT_ID, CLIENT_ID, CLIENT_SECRET in .env
       workspace errors → check PBI_WORKSPACE_ID and app membership
"""
import logging, time
from typing import Optional
import pandas as pd, requests

log = logging.getLogger(__name__)
PBI_BASE = "https://api.powerbi.com/v1.0/myorg"

class PowerBIConnector:
    def __init__(self, settings):
        self.settings = settings
        self._token: Optional[str] = None
        self._token_expiry: float = 0

    def get_token(self):
        if self._token and time.time() < self._token_expiry - 60:
            return self._token
        url = f"https://login.microsoftonline.com/{self.settings.tenant_id}/oauth2/v2.0/token"
        resp = requests.post(url, data={
            "grant_type": "client_credentials", "client_id": self.settings.client_id,
            "client_secret": self.settings.client_secret,
            "scope": "https://analysis.windows.net/powerbi/api/.default",
        }, timeout=30)
        if resp.status_code != 200:
            raise ConnectionError(f"Azure AD auth failed ({resp.status_code}): {resp.text}")
        d = resp.json()
        self._token = d["access_token"]
        self._token_expiry = time.time() + d.get("expires_in", 3600)
        log.info("Azure AD authenticated")
        return self._token

    def _headers(self):
        return {"Authorization": f"Bearer {self.get_token()}", "Content-Type": "application/json"}

    def _api(self, method, path, **kwargs):
        url = f"{PBI_BASE}/{path}"
        for attempt in range(1, 4):
            resp = getattr(requests, method)(url, headers=self._headers(), timeout=60, **kwargs)
            if resp.status_code == 429:
                time.sleep(int(resp.headers.get("Retry-After", 30)))
                continue
            return resp
        raise RuntimeError(f"API failed after 3 retries: {path}")

    def test_connection(self):
        resp = self._api("get", f"groups/{self.settings.workspace_id}/datasets")
        if resp.status_code != 200:
            raise ConnectionError(f"PBI connection failed ({resp.status_code}): {resp.text}")
        log.info("Power BI OK — %d datasets in workspace", len(resp.json().get("value", [])))

    def get_or_create_dataset(self, name, df):
        resp = self._api("get", f"groups/{self.settings.workspace_id}/datasets")
        resp.raise_for_status()
        existing = {d["name"]: d["id"] for d in resp.json().get("value", [])}
        if name in existing:
            log.info("Dataset '%s' exists", name)
            return existing[name]
        TYPE_MAP = {"int64":"Int64","int32":"Int64","float64":"Double","float32":"Double",
                    "bool":"Boolean","datetime64[ns]":"DateTime","object":"String"}
        schema = {"name": name, "defaultMode": "Push", "tables": [{"name": name,
            "columns": [{"name": c, "dataType": TYPE_MAP.get(str(df[c].dtype),"String")} for c in df.columns]}]}
        resp = self._api("post", f"groups/{self.settings.workspace_id}/datasets?defaultRetentionPolicy=basicFIFO", json=schema)
        if resp.status_code not in (200, 201):
            raise RuntimeError(f"Dataset create failed ({resp.status_code}): {resp.text}")
        dataset_id = resp.json()["id"]
        log.info("Dataset '%s' created — id: %s", name, dataset_id)
        return dataset_id

    def clear_table(self, dataset_id, table_name):
        self._api("delete", f"groups/{self.settings.workspace_id}/datasets/{dataset_id}/tables/{table_name}/rows")
        log.info("Table '%s' cleared", table_name)

    def push_dataframe(self, dataset_id, table_name, df, batch_size=9000):
        df = df.copy()
        for col in df.select_dtypes(include=["datetime64[ns]"]).columns:
            df[col] = df[col].dt.strftime("%Y-%m-%dT%H:%M:%S").where(df[col].notna(), None)
        df = df.where(pd.notna(df), None)
        total, pushed = len(df), 0
        for i in range(0, total, batch_size):
            batch = df.iloc[i:i+batch_size]
            resp = self._api("post",
                f"groups/{self.settings.workspace_id}/datasets/{dataset_id}/tables/{table_name}/rows",
                json={"rows": batch.to_dict(orient="records")})
            if resp.status_code not in (200, 201):
                raise RuntimeError(f"Push failed at batch {i//batch_size+1}: {resp.text}")
            pushed += len(batch)
            log.info("  Pushed %d / %d rows", pushed, total)
        log.info("Push complete: %d rows → '%s'", total, table_name)

    def trigger_refresh(self, dataset_id):
        resp = self._api("post",
            f"groups/{self.settings.workspace_id}/datasets/{dataset_id}/refreshes",
            json={"notifyOption": "MailOnFailure"})
        log.info("Refresh triggered" if resp.status_code in (200,202) else f"Refresh: HTTP {resp.status_code}")
