"""
tools/inspect_schema.py — SAP HANA schema inspector
Usage:
  python tools/inspect_schema.py --table OITM
  python tools/inspect_schema.py --custom
  python tools/inspect_schema.py --search Marca
  python tools/inspect_schema.py --warehouses
"""
import sys, argparse
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))
from config.settings import Settings
from hana_connector import HANAConnector

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--table", help="Show columns for a table")
    parser.add_argument("--custom", action="store_true", help="List all U_ custom fields")
    parser.add_argument("--search", help="Search column names")
    parser.add_argument("--warehouses", action="store_true")
    args = parser.parse_args()
    settings = Settings()
    hana = HANAConnector(settings.hana)
    if args.table:
        df = hana.get_table_columns(args.table)
        print(f"\nColumns in {args.table} ({len(df)} fields):")
        print(df.to_string(index=False))
    elif args.custom:
        df = hana.get_custom_fields()
        print(f"\nCustom U_ fields ({len(df)} total):")
        print(df.to_string(index=False))
    elif args.search:
        df = hana.run_query(f"""
            SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE_NAME FROM SYS.TABLE_COLUMNS
            WHERE SCHEMA_NAME = '{settings.hana.schema}' AND UPPER(COLUMN_NAME) LIKE UPPER('%{args.search}%')
            ORDER BY TABLE_NAME, COLUMN_NAME""", "search")
        print(f"\nResults for '{args.search}':")
        print(df.to_string(index=False))
    elif args.warehouses:
        df = hana.run_query('SELECT "WhsCode","WhsName","Inactive" FROM "OWHS" ORDER BY "WhsCode"', "whs")
        print(df.to_string(index=False))
    else:
        for t in ["OINV","INV1","ODLN","DLN1","ORDR","RDR1","OCRD","OSLP","OITM","OITB","OITW"]:
            try:
                df = hana.run_query(f'SELECT COUNT(*) AS N FROM "{t}"', t)
                print(f"{t:<10}  {df['N'].iloc[0]:>10,}")
            except Exception as e:
                print(f"{t:<10}  ERROR: {e}")

if __name__ == "__main__":
    main()
