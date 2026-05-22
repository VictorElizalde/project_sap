# SAP HANA → Power BI Automated Pipeline

Replaces the weekly manual Excel export workflow.
Runs every Monday at 7:00 AM, pushes fresh data from SAP B1 HANA
directly into Power BI datasets — no human intervention needed.

---

## What this does

```
SAP HANA (HDBCLI) → 4 SQL queries → pandas DataFrames → Power BI REST API → Power BI datasets
```

Every Monday at 7am a Windows scheduled task runs `main.py` which:
1. Connects to SAP HANA using read-only credentials
2. Runs 4 SQL queries (stock, delivery notes, pending orders, family mapping)
3. Validates results (row counts, null checks)
4. Pushes data to 4 Power BI Push datasets
5. Logs everything to `logs/pipeline.log`

Power BI reports built on top of these datasets refresh automatically.

---

## Project structure

```
pbi_pipeline/
├── main.py                      ← Entry point. Run this.
├── pipeline.py                  ← Orchestrates all steps
├── hana_connector.py            ← SAP HANA connection & query execution
├── pbi_connector.py             ← Power BI REST API: auth, push, refresh
├── requirements.txt             ← Python dependencies
├── .env.example                 ← Copy to .env and fill credentials
├── .gitignore
│
├── config/
│   └── settings.py              ← THE ONLY FILE YOU EDIT (or use .env)
│
├── queries/                     ← SQL files (one per Power BI dataset)
│   ├── 01_RAWstock.sql
│   ├── 02_RAWalbaranes.sql
│   ├── 03_RAWpedidosPendientes.sql
│   └── 04_RAWfamilias.sql
│
├── tools/
│   ├── inspect_schema.py        ← Debug field names / warehouse codes
│   └── schedule_windows.py     ← Install Windows scheduled task
│
├── docs/
│   └── AZURE_SETUP.md          ← One-time Azure app registration guide
│
└── logs/
    └── pipeline.log             ← Full run history with timestamps
```

---

## Quick start

### 1. Install dependencies
```bash
pip install -r requirements.txt
```

### 2. Configure credentials
```bash
cp .env.example .env
# Edit .env with your SAP HANA and Power BI credentials
# See docs/AZURE_SETUP.md for Power BI setup
```

### 3. Test connections
```bash
python main.py --dry-run
```

### 4. Run the full pipeline once manually
```bash
python main.py
```

### 5. Install the Monday 7am scheduled task (run as Administrator)
```bash
python tools/schedule_windows.py --install
```

---

## Common commands

```bash
# Full pipeline
python main.py

# Single query only
python main.py --query stock
python main.py --query albaranes
python main.py --query pedidos
python main.py --query familias

# Test connections only
python main.py --dry-run

# Trigger Power BI refresh without re-pushing data
python main.py --refresh-only

# Inspect SAP schema (for debugging field name errors)
python tools/inspect_schema.py --table OITM
python tools/inspect_schema.py --custom            # all U_ fields
python tools/inspect_schema.py --search Marca      # find a field name
python tools/inspect_schema.py --warehouses        # list warehouse codes

# Scheduled task management
python tools/schedule_windows.py --install
python tools/schedule_windows.py --status
python tools/schedule_windows.py --remove
```

---

## Cline instructions

If you are Cline running this project, follow this order:

1. **First run**: `python main.py --dry-run` — fix any connection errors
2. **Check schema**: If queries return NULL columns, run `python tools/inspect_schema.py --custom`
   to find the correct U_ field names and update the .sql files in queries/
3. **Fix warehouse codes**: Run `python tools/inspect_schema.py --warehouses`
   and update the `NOT IN ('98','99')` exclusion in 01_RAWstock.sql if needed
4. **Full run**: `python main.py` — first run creates datasets and prints their IDs
5. **Save dataset IDs**: Copy the printed dataset IDs into .env
6. **Schedule**: `python tools/schedule_windows.py --install`

All errors are self-descriptive. Read the error message — it tells you exactly what to fix.

---

## Troubleshooting

| Error | Fix |
|---|---|
| `hdbcli not found` | `pip install hdbcli` |
| `Connection refused` | Check HANA_HOST and HANA_PORT in .env |
| `Invalid schema name` | Check HANA_SCHEMA — find it in SAP B1 → Administration → Company Details |
| `Authentication failed` | Verify PBI_TENANT_ID, CLIENT_ID, CLIENT_SECRET |
| `Workspace not found` | Check PBI_WORKSPACE_ID from the app.powerbi.com URL |
| `App not authorized` | Add the app as Member to the workspace (docs/AZURE_SETUP.md step 5) |
| `NULL columns in result` | Field name mismatch — run `inspect_schema.py --custom` |
| `0 rows returned` | Check date filter in SQL file, verify schema name |
