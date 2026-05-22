# Rentabilidad Pipeline — SAP HANA → Power BI

Reemplaza: `2026_Rentabilidad_por_FAMILIA.xlsx`
Ejecutar cada lunes a las 7:00 AM automáticamente.

## Queries
| Archivo | Dataset Power BI | Descripción |
|---|---|---|
| 05_RAWventas.sql | RAWventas_all | Facturas de TODOS los canales sin filtro |
| 06_RAWinventario.sql | RAWinventario | Snapshot mensual de inventario por familia |
| 02_RAWalbaranes.sql | RAWalbaranes | Albaranes de entrega |
| 04_RAWfamilias.sql | RAWfamilias | Mapping Familia → Canal |

## Inicio rápido
```bash
pip install -r requirements.txt
cp .env.example .env        # rellenar credenciales
python main.py --dry-run    # probar conexiones
python main.py              # ejecución completa
python tools/schedule_windows.py --install  # tarea lunes 7am (como Administrador)
```

## Comandos
```bash
python main.py --query ventas
python main.py --query inventario
python main.py --query albaranes
python main.py --query familias
python tools/inspect_schema.py --custom
python tools/inspect_schema.py --warehouses
```
