# Hospitality Pipeline — SAP HANA → Power BI

Reemplaza: `Objetivos_y_Resultados_2026_Hospitality.xlsx`
Ejecutar cada lunes a las 7:00 AM automáticamente.

## Queries
| Archivo | Dataset Power BI | Descripción |
|---|---|---|
| 05_RAWventas.sql | RAWventas_hospitality | Facturas filtradas a familias Hospitality |
| 02_RAWalbaranes.sql | RAWalbaranes | Albaranes de entrega |
| 07_RAWclientes.sql | RAWclientes | Maestro clientes + flag nuevo 2026 automático |
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
python main.py --query albaranes
python main.py --query clientes
python main.py --query familias
python tools/inspect_schema.py --custom
python tools/inspect_schema.py --search Marca
```

## ⚠ Objetivos manuales
Los objetivos anuales/mensuales NO vienen de SAP.
Crear lista SharePoint `Objetivos_PowerBI` — ver Sección 8 del Manual Técnico.
