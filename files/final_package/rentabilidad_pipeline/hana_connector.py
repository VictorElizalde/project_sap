"""
hana_connector.py — SAP HANA connection and query execution.
Cline: if connection fails, check HANA_HOST, HANA_PORT, HANA_USER, HANA_PASSWORD in .env
       Run: python tools/inspect_schema.py to list tables and verify field names.
"""
import logging, time
from pathlib import Path
from typing import Optional
import pandas as pd

try:
    from hdbcli import dbapi
except ImportError:
    raise ImportError("Run: pip install hdbcli")

log = logging.getLogger(__name__)

class HANAConnector:
    def __init__(self, settings):
        self.settings = settings
        self._conn: Optional[dbapi.Connection] = None

    def connect(self):
        if self._conn and self._ping():
            return self._conn
        log.info("Connecting to SAP HANA at %s:%s ...", self.settings.host, self.settings.port)
        for attempt in range(1, 4):
            try:
                self._conn = dbapi.connect(
                    address=self.settings.host, port=self.settings.port,
                    user=self.settings.user, password=self.settings.password,
                    currentSchema=self.settings.schema,
                    encrypt=True, sslValidateCertificate=False, connectTimeout=15,
                )
                log.info("Connected (schema: %s)", self.settings.schema)
                return self._conn
            except dbapi.Error as e:
                log.warning("Attempt %d/3 failed: %s", attempt, e)
                if attempt < 3: time.sleep(3)
                else: raise ConnectionError(f"Cannot connect to HANA: {e}")

    def _ping(self):
        try:
            self._conn.cursor().execute("SELECT 1 FROM DUMMY")
            return True
        except: return False

    def test_connection(self):
        c = self.connect().cursor()
        c.execute("SELECT CURRENT_DATE, CURRENT_USER FROM DUMMY")
        row = c.fetchone()
        log.info("HANA OK — date: %s, user: %s", row[0], row[1])

    def run_query(self, sql, query_name="query"):
        conn = self.connect()
        log.info("Running: %s", query_name)
        start = time.time()
        try:
            conn.cursor().execute(f'SET SCHEMA "{self.settings.schema}"')
            df = pd.read_sql(sql, conn)
            log.info("'%s' — %d rows in %.1fs", query_name, len(df), time.time()-start)
            return df
        except dbapi.Error as e:
            log.error("Query '%s' failed: %s", query_name, e)
            raise

    def run_query_from_file(self, filepath, query_name=None):
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError(f"SQL file not found: {filepath}")
        return self.run_query(path.read_text(encoding="utf-8"), query_name or path.stem)

    def get_table_columns(self, table_name):
        return self.run_query(f"""
            SELECT COLUMN_NAME, DATA_TYPE_NAME, LENGTH, NULLABLE
            FROM SYS.TABLE_COLUMNS
            WHERE SCHEMA_NAME = '{self.settings.schema}' AND TABLE_NAME = '{table_name.upper()}'
            ORDER BY POSITION""", f"schema_{table_name}")

    def get_custom_fields(self):
        return self.run_query(f"""
            SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE_NAME
            FROM SYS.TABLE_COLUMNS
            WHERE SCHEMA_NAME = '{self.settings.schema}' AND COLUMN_NAME LIKE 'U_%'
            ORDER BY TABLE_NAME, COLUMN_NAME""", "custom_fields")
