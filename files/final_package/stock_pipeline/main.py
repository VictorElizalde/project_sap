"""
SAP HANA → Power BI Automated Pipeline
=======================================
Entry point. Run this script to execute the full pipeline:
  1. Connect to SAP HANA
  2. Run all SQL queries
  3. Push results to Power BI datasets
  4. Trigger dataset refresh
  5. Log everything

Usage:
  python main.py                  # full pipeline
  python main.py --query stock    # single query only
  python main.py --dry-run        # test connections only, no push

Cline: if any step fails, check logs/pipeline.log for the full traceback.
"""

import argparse
import sys
import logging
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv

# Load .env BEFORE importing Settings (Settings reads os.getenv at import time)
load_dotenv()

from hana_connector import HANAConnector
from pbi_connector import PowerBIConnector
from pipeline import Pipeline
from config.settings import Settings

# ── Logging setup ──────────────────────────────────────────────────────────────
log_dir = Path("logs")
log_dir.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(log_dir / "pipeline.log", encoding="utf-8"),
    ],
)
log = logging.getLogger(__name__)


def main():
    parser = argparse.ArgumentParser(description="SAP HANA → Power BI Pipeline")
    parser.add_argument("--query",   help="Run a single query by name (stock, albaranes, pedidos, familias)")
    parser.add_argument("--dry-run", action="store_true", help="Test connections only, do not push data")
    parser.add_argument("--refresh-only", action="store_true", help="Trigger Power BI refresh without re-pushing data")
    args = parser.parse_args()

    log.info("=" * 60)
    log.info("Pipeline started  |  %s", datetime.now().strftime("%A %d %B %Y  %H:%M"))
    log.info("=" * 60)

    # ── Load settings ──────────────────────────────────────────────────────────
    load_dotenv()  # load .env file before reading environment variables
    settings = Settings()
    settings.validate()  # will raise clearly if anything is missing

    # ── Init connectors ────────────────────────────────────────────────────────
    hana = HANAConnector(settings.hana)
    pbi  = PowerBIConnector(settings.powerbi)

    # ── Run pipeline ───────────────────────────────────────────────────────────
    pipeline = Pipeline(hana, pbi, settings)

    if args.dry_run:
        log.info("DRY RUN — testing connections only")
        hana.test_connection()
        pbi.test_connection()
        log.info("All connections OK")
        return

    if args.refresh_only:
        log.info("REFRESH ONLY — triggering Power BI dataset refresh")
        pbi.trigger_refresh(settings.powerbi.dataset_id)
        return

    if args.query:
        pipeline.run_single(args.query)
    else:
        pipeline.run_all()

    log.info("=" * 60)
    log.info("Pipeline completed successfully")
    log.info("=" * 60)


if __name__ == "__main__":
    main()
