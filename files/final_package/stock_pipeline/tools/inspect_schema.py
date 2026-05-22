"""
tools/inspect_schema.py
=======================
Diagnostic tool for Cline to use when queries return NULL columns
or fail with "invalid column name" errors.

Usage:
  python tools/inspect_schema.py                        # list all SAP tables
  python tools/inspect_schema.py --table OITM           # columns of a table
  python tools/inspect_schema.py --custom               # all U_ custom fields
  python tools/inspect_schema.py --search Marca         # search field names

Cline: run this first when a query fails with column errors.
"""

import sys
import argparse
from pathlib import Path

# Add parent to path so we can import our modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from config.settings import Settings
from hana_connector import HANAConnector


def main():
    parser = argparse.ArgumentParser(description="SAP HANA schema inspector")
    parser.add_argument("--table",  help="Show columns for a specific table (e.g. OITM)")
    parser.add_argument("--custom", action="store_true", help="List all U_ custom fields")
    parser.add_argument("--search", help="Search for a column name across all tables")
    parser.add_argument("--warehouses", action="store_true", help="List all warehouse codes (OWHS)")
    parser.add_argument("--families",   action="store_true", help="List all item groups (OITB)")
    parser.add_argument("--agents",     action="store_true", help="List all sales agents (OSLP)")
    args = parser.parse_args()

    settings = Settings()
    hana = HANAConnector(settings.hana)

    if args.table:
        df = hana.get_table_columns(args.table)
        print(f"\nColumns in {args.table.upper()} ({len(df)} fields):")
        print(df.to_string(index=False))

    elif args.custom:
        df = hana.get_custom_fields()
        print(f"\nCustom U_ fields ({len(df)} total):")
        print(df.to_string(index=False))

    elif args.search:
        sql = f"""
            SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE_NAME
            FROM   SYS.TABLE_COLUMNS
            WHERE  SCHEMA_NAME = '{settings.hana.schema}'
            AND    UPPER(COLUMN_NAME) LIKE UPPER('%{args.search}%')
            ORDER  BY TABLE_NAME, COLUMN_NAME
        """
        df = hana.run_query(sql, "search")
        print(f"\nColumns matching '{args.search}' ({len(df)} results):")
        print(df.to_string(index=False))

    elif args.warehouses:
        sql = 'SELECT "WhsCode", "WhsName", "Inactive" FROM "OWHS" ORDER BY "WhsCode"'
        df = hana.run_query(sql, "warehouses")
        print(f"\nWarehouse codes ({len(df)} warehouses):")
        print(df.to_string(index=False))

    elif args.families:
        sql = 'SELECT "ItmsGrpCod", "ItmsGrpNam" FROM "OITB" ORDER BY "ItmsGrpNam"'
        df = hana.run_query(sql, "families")
        print(f"\nItem families ({len(df)} groups):")
        print(df.to_string(index=False))

    elif args.agents:
        sql = 'SELECT "SlpCode", "SlpName", "Active" FROM "OSLP" ORDER BY "SlpName"'
        df = hana.run_query(sql, "agents")
        print(f"\nSales agents ({len(df)} agents):")
        print(df.to_string(index=False))

    else:
        # Default: list all main SAP B1 tables with row counts
        tables = [
            "OITM", "OITB", "OITW", "OINM", "OPDN", "PDN1",
            "OINV", "INV1", "ODLN", "DLN1", "ORDR", "RDR1",
            "OCRD", "OSLP", "OWHS", "OPOR", "POR1"
        ]
        print(f"\nKey SAP B1 tables in schema '{settings.hana.schema}':")
        print(f"{'Table':<10}  {'Rows':>10}  Status")
        print("-" * 35)
        for t in tables:
            try:
                df = hana.run_query(f'SELECT COUNT(*) AS N FROM "{t}"', t)
                print(f"{t:<10}  {df['N'].iloc[0]:>10,}  OK")
            except Exception as e:
                print(f"{t:<10}  {'':>10}  ERROR: {e}")


if __name__ == "__main__":
    main()
