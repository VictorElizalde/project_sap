"""
pipeline.py
===========
Orchestrates the full HANA → Power BI pipeline.
Runs each query, validates the result, clears the target table,
and pushes the fresh data. All steps are logged.

Cline: if a specific query fails, run:
  python main.py --query <name>
to isolate and debug it without re-running everything.
"""

import logging
from pathlib import Path
import pandas as pd

log = logging.getLogger(__name__)


# ── Query registry ─────────────────────────────────────────────────────────────
# Each entry maps a short name → (sql_file, dataset_name, min_expected_rows)
QUERIES = {
    "stock": (
        "queries/01_RAWstock.sql",
        "RAWstock",
        50,         # alert if fewer than 50 rows — something is wrong
    ),
    "albaranes": (
        "queries/02_RAWalbaranes.sql",
        "RAWalbaranes",
        100,
    ),
    "pedidos": (
        "queries/03_RAWpedidosPendientes.sql",
        "RAWpedidosPendientes",
        0,          # can legitimately be 0 if no open orders
    ),
    "familias": (
        "queries/04_RAWfamilias.sql",
        "RAWfamilias",
        10,
    ),
}


class Pipeline:
    def __init__(self, hana, pbi, settings):
        self.hana     = hana
        self.pbi      = pbi
        self.settings = settings
        self.results  = {}   # summary of each step: {query_name: {rows, status, error}}

    # ── Public methods ─────────────────────────────────────────────────────────
    def run_all(self):
        """Run every query in QUERIES and push all to Power BI."""
        log.info("Running full pipeline (%d queries)", len(QUERIES))
        errors = []

        for name in QUERIES:
            try:
                self.run_single(name)
            except Exception as e:
                log.error("Query '%s' failed — continuing with others", name)
                self.results[name] = {"status": "FAILED", "error": str(e), "rows": 0}
                errors.append(name)

        self._print_summary()

        if errors:
            raise RuntimeError(
                f"Pipeline completed with errors in: {', '.join(errors)}\n"
                f"Check logs/pipeline.log for details."
            )

    def run_single(self, query_name: str):
        """Run a single query by name and push it to Power BI."""
        if query_name not in QUERIES:
            raise ValueError(
                f"Unknown query '{query_name}'. Available: {', '.join(QUERIES.keys())}"
            )

        sql_file, dataset_name, min_rows = QUERIES[query_name]

        log.info("─" * 50)
        log.info("Starting: %s → %s", query_name, dataset_name)

        # Step 1 — Run SQL against HANA
        df = self._run_query(sql_file, query_name)

        # Step 2 — Validate result
        self._validate(df, query_name, min_rows)

        # Step 3 — Get or create Power BI dataset
        dataset_id = self._get_dataset_id(dataset_name, df)

        # Step 4 — Clear old rows and push fresh data
        self.pbi.clear_table(dataset_id, dataset_name)
        self.pbi.push_dataframe(
            dataset_id,
            dataset_name,
            df,
            batch_size=self.settings.batch_size,
        )

        self.results[query_name] = {
            "status":  "OK",
            "rows":    len(df),
            "dataset": dataset_name,
        }
        log.info("Done: %s (%d rows)", query_name, len(df))

    # ── Private helpers ────────────────────────────────────────────────────────
    def _run_query(self, sql_file: str, name: str) -> pd.DataFrame:
        path = Path(sql_file)
        if not path.exists():
            raise FileNotFoundError(
                f"SQL file not found: {sql_file}\n"
                f"Make sure the queries/ folder contains all 4 .sql files."
            )
        return self.hana.run_query_from_file(path, name)

    def _validate(self, df: pd.DataFrame, name: str, min_rows: int):
        """Basic sanity checks on query results before pushing."""
        if df is None or len(df) == 0:
            if min_rows > 0:
                raise ValueError(
                    f"Query '{name}' returned 0 rows — expected at least {min_rows}.\n"
                    f"Check the WHERE clause in queries/{name}.sql and confirm the\n"
                    f"schema name is correct: {self.settings.hana.schema}"
                )
            else:
                log.warning("Query '%s' returned 0 rows (this may be expected)", name)
                return

        if len(df) < min_rows:
            log.warning(
                "Query '%s' returned only %d rows (expected ≥ %d) — check filters",
                name, len(df), min_rows
            )

        # Check for columns that are entirely null (usually means a wrong field name)
        null_cols = [c for c in df.columns if df[c].isna().all()]
        if null_cols:
            log.warning(
                "Query '%s' — these columns are entirely NULL: %s\n"
                "  → Likely means the U_ custom field name is different in your schema.\n"
                "  → Run: python tools/inspect_schema.py to check actual field names.",
                name, null_cols
            )

        log.info("Validation OK — %d rows, %d columns", len(df), len(df.columns))

    def _get_dataset_id(self, dataset_name: str, df: pd.DataFrame) -> str:
        """Get dataset ID from settings or auto-create if not set."""
        dataset_id = self.settings.powerbi.datasets.get(dataset_name, "")

        if dataset_id:
            log.info("Using existing dataset id: %s", dataset_id[:8] + "...")
            return dataset_id

        # Not configured — create it and log the ID for the user to save
        log.info("No dataset ID configured for '%s' — creating new dataset", dataset_name)
        dataset_id = self.pbi.get_or_create_dataset(dataset_name, df)
        log.info(
            "  ✓ New dataset created. Add to config/settings.py:\n"
            "    datasets[\"%s\"] = \"%s\"",
            dataset_name, dataset_id
        )
        return dataset_id

    def _print_summary(self):
        log.info("")
        log.info("=" * 50)
        log.info("PIPELINE SUMMARY")
        log.info("=" * 50)
        for name, result in self.results.items():
            status = result["status"]
            if status == "OK":
                log.info("  ✓  %-20s  %d rows", name, result["rows"])
            else:
                log.error("  ✗  %-20s  FAILED: %s", name, result.get("error", ""))
        log.info("=" * 50)
