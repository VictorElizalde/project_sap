"""
main.py — SAP HANA → Power BI Pipeline
Run this file to execute the full pipeline.

Usage:
  python main.py                  # full pipeline
  python main.py --query ventas   # single query
  python main.py --dry-run        # test connections only
"""
import argparse, sys, logging
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()
Path("logs").mkdir(exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout),
              logging.FileHandler("logs/pipeline.log", encoding="utf-8")],
)
log = logging.getLogger(__name__)

from hana_connector import HANAConnector
from pbi_connector import PowerBIConnector
from pipeline import Pipeline
from config.settings import Settings

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--query", help="Run single query by name")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    log.info("=" * 60)
    log.info("Pipeline started  |  %s", datetime.now().strftime("%A %d %B %Y  %H:%M"))
    log.info("=" * 60)

    settings = Settings()
    settings.validate()

    hana = HANAConnector(settings.hana)
    pbi  = PowerBIConnector(settings.powerbi)

    if args.dry_run:
        log.info("DRY RUN — testing connections only")
        hana.test_connection()
        pbi.test_connection()
        log.info("All connections OK")
        return

    pipeline = Pipeline(hana, pbi, settings)
    if args.query:
        pipeline.run_single(args.query)
    else:
        pipeline.run_all()

    log.info("Pipeline completed successfully")

if __name__ == "__main__":
    main()
