"""
hana_connector.py
=================
Handles all SAP HANA connections and query execution.

Cline: if connection fails, common issues are:
  - hdbcli not installed → run: pip install hdbcli
  - Wrong port → check SAP B1 instance number (instance 00 = port 30015, 01 = 30115)
  - Firewall blocking port → confirm with IT that port is open from this machine
  - Schema name wrong → check in SAP B1: Administration → System Initialization → Company Details
"""

import logging
import time
from pathlib import Path
from typing import Optional, Union

import pandas as pd

try:
    from hdbcli import dbapi
except ImportError:
    raise ImportError(
        "hdbcli not installed. Run:\n"
        "  pip install hdbcli\n"
        "This is the official SAP HANA Python driver."
    )

log = logging.getLogger(__name__)


class HANAConnector:
    def __init__(self, settings):
        self.settings = settings
        self._conn: Optional[dbapi.Connection] = None

    # ── Connection ─────────────────────────────────────────────────────────────
    def connect(self) -> dbapi.Connection:
        """Open and return a HANA connection. Retries up to 3 times."""
        if self._conn and self._ping():
            return self._conn

        log.info("Connecting to SAP HANA at %s:%s ...", self.settings.host, self.settings.port)

        for attempt in range(1, 4):
            try:
                self._conn = dbapi.connect(
                    address=self.settings.host,
                    port=self.settings.port,
                    user=self.settings.user,
                    password=self.settings.password,
                    currentSchema=self.settings.schema,
                    encrypt=False,                  # disabled for internal/local SAP installs
                    connectTimeout=15,
                )
                log.info("Connected to HANA (schema: %s)", self.settings.schema)
                return self._conn

            except dbapi.Error as e:
                log.warning("Connection attempt %d/3 failed: %s", attempt, e)
                if attempt < 3:
                    time.sleep(3)
                else:
                    raise ConnectionError(
                        f"Could not connect to SAP HANA after 3 attempts.\n"
                        f"Host: {self.settings.host}:{self.settings.port}\n"
                        f"Error: {e}\n\n"
                        f"Common fixes:\n"
                        f"  1. Check host/port in config/settings.py\n"
                        f"  2. Confirm PBI_READONLY user exists and has SELECT on {self.settings.schema}\n"
                        f"  3. Confirm firewall allows port {self.settings.port}"
                    )

    def disconnect(self):
        if self._conn:
            try:
                self._conn.close()
                log.info("HANA connection closed")
            except Exception:
                pass
            self._conn = None

    def _ping(self) -> bool:
        try:
            cursor = self._conn.cursor()
            cursor.execute("SELECT 1 FROM DUMMY")
            return True
        except Exception:
            return False

    def test_connection(self):
        conn = self.connect()
        cursor = conn.cursor()
        cursor.execute("SELECT CURRENT_DATE, CURRENT_USER FROM DUMMY")
        row = cursor.fetchone()
        log.info("HANA test OK — date: %s, user: %s", row[0], row[1])
        return True

    # ── Query execution ────────────────────────────────────────────────────────
    def run_query(self, sql: str, query_name: str = "query") -> pd.DataFrame:
        """
        Execute a SQL string and return results as a DataFrame.
        Automatically sets the schema before running.
        """
        conn = self.connect()

        log.info("Running query: %s", query_name)
        start = time.time()

        try:
            # Ensure schema is set for this session
            cursor = conn.cursor()
            cursor.execute(f'SET SCHEMA "{self.settings.schema}"')

            df = pd.read_sql(sql, conn)

            elapsed = time.time() - start
            log.info(
                "Query '%s' completed — %d rows in %.1fs",
                query_name, len(df), elapsed
            )
            return df

        except dbapi.Error as e:
            log.error("Query '%s' failed: %s", query_name, e)
            log.error("First 500 chars of SQL:\n%s", sql[:500])
            raise

    def run_query_from_file(self, filepath: Union[str, Path], query_name: str = None) -> pd.DataFrame:
        """Load SQL from file and execute it."""
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError(f"SQL file not found: {filepath}")

        sql = path.read_text(encoding="utf-8")
        name = query_name or path.stem
        return self.run_query(sql, name)

    # ── Schema introspection (used by Cline for debugging) ────────────────────
    def get_table_columns(self, table_name: str) -> pd.DataFrame:
        """Return all columns and types for a SAP B1 table. Useful for debugging."""
        sql = f"""
            SELECT COLUMN_NAME, DATA_TYPE_NAME, LENGTH, NULLABLE
            FROM   SYS.TABLE_COLUMNS
            WHERE  SCHEMA_NAME = '{self.settings.schema}'
            AND    TABLE_NAME  = '{table_name.upper()}'
            ORDER  BY POSITION
        """
        return self.run_query(sql, f"schema_{table_name}")

    def list_tables(self, filter_prefix: str = "") -> pd.DataFrame:
        """List all tables in the company schema."""
        where = f"AND TABLE_NAME LIKE '{filter_prefix}%'" if filter_prefix else ""
        sql = f"""
            SELECT TABLE_NAME, RECORD_COUNT
            FROM   SYS.M_TABLES
            WHERE  SCHEMA_NAME = '{self.settings.schema}'
            {where}
            ORDER  BY TABLE_NAME
        """
        return self.run_query(sql, "list_tables")

    def get_custom_fields(self, table_prefix: str = "U_") -> pd.DataFrame:
        """List all custom U_ fields in the schema. Critical for verifying field names."""
        sql = f"""
            SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE_NAME
            FROM   SYS.TABLE_COLUMNS
            WHERE  SCHEMA_NAME = '{self.settings.schema}'
            AND    COLUMN_NAME LIKE '{table_prefix}%'
            ORDER  BY TABLE_NAME, COLUMN_NAME
        """
        return self.run_query(sql, "custom_fields")
