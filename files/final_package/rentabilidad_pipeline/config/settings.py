"""
config/settings.py — Rentabilidad por Familia Pipeline
"""
import os
from dataclasses import dataclass, field

@dataclass
class HANASettings:
    host:     str = os.getenv("HANA_HOST",     "192.168.x.x")
    port:     int = int(os.getenv("HANA_PORT", "30015"))
    user:     str = os.getenv("HANA_USER",     "PBI_READONLY")
    password: str = os.getenv("HANA_PASSWORD", "")
    schema:   str = os.getenv("HANA_SCHEMA",   "SBO_YOURCOMPANY")

@dataclass
class PowerBISettings:
    tenant_id:     str = os.getenv("PBI_TENANT_ID",     "")
    client_id:     str = os.getenv("PBI_CLIENT_ID",     "")
    client_secret: str = os.getenv("PBI_CLIENT_SECRET", "")
    workspace_id:  str = os.getenv("PBI_WORKSPACE_ID",  "")
    datasets: dict = field(default_factory=lambda: {
        "RAWventas_all":  os.getenv("PBI_DATASET_VENTAS_ALL",  ""),
        "RAWinventario":  os.getenv("PBI_DATASET_INVENTARIO",  ""),
        "RAWalbaranes":   os.getenv("PBI_DATASET_ALBARANES",   ""),
        "RAWfamilias":    os.getenv("PBI_DATASET_FAMILIAS",    ""),
    })

@dataclass
class Settings:
    hana:        HANASettings    = field(default_factory=HANASettings)
    powerbi:     PowerBISettings = field(default_factory=PowerBISettings)
    queries_dir: str = "queries"
    batch_size:  int = 9000

    def validate(self):
        errors = []
        if not self.hana.host or self.hana.host == "192.168.x.x":
            errors.append("HANA_HOST not set")
        if not self.hana.password:
            errors.append("HANA_PASSWORD not set")
        if not self.hana.schema or self.hana.schema == "SBO_YOURCOMPANY":
            errors.append("HANA_SCHEMA not set")
        if not self.powerbi.tenant_id:
            errors.append("PBI_TENANT_ID not set")
        if not self.powerbi.client_id:
            errors.append("PBI_CLIENT_ID not set")
        if not self.powerbi.client_secret:
            errors.append("PBI_CLIENT_SECRET not set")
        if not self.powerbi.workspace_id:
            errors.append("PBI_WORKSPACE_ID not set")
        if errors:
            raise ValueError("Missing configuration:\n" + "\n".join(f"  ✗  {e}" for e in errors))
