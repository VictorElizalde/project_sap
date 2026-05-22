"""
pipeline.py — Rentabilidad por Familia Pipeline
================================================
Runs 5 queries and pushes to Power BI.

Cline: run `python main.py --dry-run` first to test connections.
Then `python main.py` for the full run.

Queries run:
  05_RAWventas.sql          → RAWventas_all      (ALL canals — no filter)
  06_RAWinventario.sql      → RAWinventario      (monthly stock snapshot by family)
  02_RAWalbaranes.sql       → RAWalbaranes
  04_RAWfamilias.sql        → RAWfamilias
"""

import logging
from pathlib import Path
import pandas as pd

log = logging.getLogger(__name__)

QUERIES = {
    "ventas":      ("queries/05_RAWventas.sql",       "RAWventas_all",   100),
    "inventario":  ("queries/06_RAWinventario.sql",   "RAWinventario",   50),
    "albaranes":   ("queries/02_RAWalbaranes.sql",    "RAWalbaranes",    100),
    "familias":    ("queries/04_RAWfamilias.sql",     "RAWfamilias",     10),
}


class Pipeline:
    def __init__(self, hana, pbi, settings):
        self.hana     = hana
        self.pbi      = pbi
        self.settings = settings
        self.results  = {}

    def run_all(self):
        log.info("Running Rentabilidad pipeline (%d queries)", len(QUERIES))
        errors = []
        for name in QUERIES:
            try:
                self.run_single(name)
            except Exception as e:
                log.error("Query '%s' failed — continuing", name)
                self.results[name] = {"status": "FAILED", "error": str(e), "rows": 0}
                errors.append(name)
        self._print_summary()
        if errors:
            raise RuntimeError(f"Pipeline completed with errors in: {', '.join(errors)}")

    def run_single(self, query_name: str):
        if query_name not in QUERIES:
            raise ValueError(f"Unknown query '{query_name}'. Available: {', '.join(QUERIES.keys())}")

        sql_file, dataset_name, min_rows = QUERIES[query_name]
        log.info("─" * 50)
        log.info("Starting: %s → %s", query_name, dataset_name)

        df = self.hana.run_query_from_file(sql_file, query_name)

        self._validate(df, query_name, min_rows)
        dataset_id = self._get_dataset_id(dataset_name, df)
        self.pbi.clear_table(dataset_id, dataset_name)
        self.pbi.push_dataframe(dataset_id, dataset_name, df, self.settings.batch_size)

        self.results[query_name] = {"status": "OK", "rows": len(df), "dataset": dataset_name}
        log.info("Done: %s (%d rows)", query_name, len(df))

    def _validate(self, df, name, min_rows):
        if df is None or len(df) == 0:
            if min_rows > 0:
                raise ValueError(f"Query '{name}' returned 0 rows — check schema and filters")
            return
        null_cols = [c for c in df.columns if df[c].isna().all()]
        if null_cols:
            log.warning("Query '%s' — entirely NULL columns: %s — check U_ field names", name, null_cols)
        log.info("Validation OK — %d rows, %d columns", len(df), len(df.columns))

    def _get_dataset_id(self, dataset_name, df):
        dataset_id = self.settings.powerbi.datasets.get(dataset_name, "")
        if dataset_id:
            return dataset_id
        dataset_id = self.pbi.get_or_create_dataset(dataset_name, df)
        log.info('  → Add to .env: PBI_DATASET_%s="%s"', dataset_name.upper().replace(" ", "_"), dataset_id)
        return dataset_id

    def _print_summary(self):
        log.info("=" * 50)
        log.info("RENTABILIDAD PIPELINE SUMMARY")
        log.info("=" * 50)
        for name, result in self.results.items():
            if result["status"] == "OK":
                log.info("  ✓  %-20s  %d rows", name, result["rows"])
            else:
                log.error("  ✗  %-20s  FAILED: %s", name, result.get("error", ""))
        log.info("=" * 50)
