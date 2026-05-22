"""
config/settings.py
==================
THE ONLY FILE YOU NEED TO EDIT.
Fill in your credentials here before running the pipeline.

Cline: if a connection fails, check these values first.
"""

import os
from dataclasses import dataclass, field


@dataclass
class HANASettings:
    # ── SAP HANA connection ────────────────────────────────────────────────────
    host:     str = field(default_factory=lambda: os.getenv("HANA_HOST",     "192.168.x.x"))
    port:     int = field(default_factory=lambda: int(os.getenv("HANA_PORT", "30015")))
    user:     str = field(default_factory=lambda: os.getenv("HANA_USER",     "PBI_READONLY"))
    password: str = field(default_factory=lambda: os.getenv("HANA_PASSWORD", ""))
    schema:   str = field(default_factory=lambda: os.getenv("HANA_SCHEMA",   "SBO_YOURCOMPANY"))


@dataclass
class PowerBISettings:
    # ── Azure App Registration (for Power BI REST API) ─────────────────────────
    # Create one at: https://portal.azure.com → App registrations
    tenant_id:     str = field(default_factory=lambda: os.getenv("PBI_TENANT_ID",     ""))
    client_id:     str = field(default_factory=lambda: os.getenv("PBI_CLIENT_ID",     ""))
    client_secret: str = field(default_factory=lambda: os.getenv("PBI_CLIENT_SECRET", ""))

    # ── Power BI workspace & datasets ─────────────────────────────────────────
    # Find these at: app.powerbi.com → workspace URL
    workspace_id:  str = field(default_factory=lambda: os.getenv("PBI_WORKSPACE_ID",  ""))

    # Dataset IDs — created automatically on first push, then fill these in
    # after the first run (pipeline prints them to the log)
    datasets: dict = field(default_factory=lambda: {
        "RAWstock":               os.getenv("PBI_DATASET_RAWSTOCK",    ""),
        "RAWalbaranes":           os.getenv("PBI_DATASET_ALBARANES",   ""),
        "RAWpedidosPendientes":   os.getenv("PBI_DATASET_PEDIDOS",     ""),
        "RAWfamilias":            os.getenv("PBI_DATASET_FAMILIAS",    ""),
    })


@dataclass
class Settings:
    hana:    HANASettings    = field(default_factory=HANASettings)
    powerbi: PowerBISettings = field(default_factory=PowerBISettings)

    # ── Query files location ───────────────────────────────────────────────────
    queries_dir: str = "queries"

    # ── How many rows to push per batch to Power BI ───────────────────────────
    # Power BI REST API limit is 10,000 rows per request
    batch_size: int = 9000

    def validate(self):
        """Raise a clear error if any required config is missing."""
        errors = []

        if not self.hana.host or self.hana.host == "192.168.x.x":
            errors.append("HANA host not set (HANA_HOST env var or config/settings.py)")
        if not self.hana.password:
            errors.append("HANA password not set (HANA_PASSWORD env var)")
        if not self.hana.schema or self.hana.schema == "SBO_YOURCOMPANY":
            errors.append("HANA schema not set (HANA_SCHEMA env var or config/settings.py)")
        if not self.powerbi.tenant_id:
            errors.append("Power BI tenant_id not set (PBI_TENANT_ID env var)")
        if not self.powerbi.client_id:
            errors.append("Power BI client_id not set (PBI_CLIENT_ID env var)")
        if not self.powerbi.client_secret:
            errors.append("Power BI client_secret not set (PBI_CLIENT_SECRET env var)")
        if not self.powerbi.workspace_id:
            errors.append("Power BI workspace_id not set (PBI_WORKSPACE_ID env var)")

        if errors:
            raise ValueError(
                "Missing configuration:\n" +
                "\n".join(f"  ✗  {e}" for e in errors) +
                "\n\nSee config/settings.py or set environment variables in .env"
            )
