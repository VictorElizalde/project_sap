@echo off
REM ============================================================
REM  run_pipelines.bat
REM  Instala dependencias y ejecuta los 3 pipelines SAP → Power BI
REM  Ejecutar como Administrador en el servidor Windows 192.168.1.4
REM ============================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================
echo  SAP HANA ^> Power BI Pipeline Runner
echo  %DATE% %TIME%
echo ============================================================
echo.

REM -- Verificar Python --
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python no encontrado. Instala Python 3.10+ desde https://python.org
    echo         Asegurate de marcar "Add Python to PATH" durante la instalacion.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('python --version') do echo [OK] %%i encontrado

REM -- Directorio base (donde esta este .bat) --
set BASE_DIR=%~dp0
echo [INFO] Directorio base: %BASE_DIR%
echo.

REM ============================================================
REM  1. STOCK PIPELINE
REM ============================================================
echo ============================================================
echo  [1/3] STOCK PIPELINE
echo ============================================================
cd /d "%BASE_DIR%stock_pipeline"

echo [INFO] Instalando dependencias...
pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo [ERROR] Fallo al instalar dependencias de stock_pipeline
    pause
    exit /b 1
)

echo [INFO] Ejecutando dry-run...
python main.py --dry-run
if errorlevel 1 (
    echo [ERROR] Dry-run de stock_pipeline fallo. Revisa la conexion HANA y Power BI.
    pause
    exit /b 1
)

echo [INFO] Ejecutando pipeline completo...
python main.py
if errorlevel 1 (
    echo [ERROR] stock_pipeline fallo.
    pause
    exit /b 1
)
echo [OK] stock_pipeline completado.
echo.

REM ============================================================
REM  2. HOSPITALITY PIPELINE
REM ============================================================
echo ============================================================
echo  [2/3] HOSPITALITY PIPELINE
echo ============================================================
cd /d "%BASE_DIR%hospitality_pipeline"

echo [INFO] Instalando dependencias...
pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo [ERROR] Fallo al instalar dependencias de hospitality_pipeline
    pause
    exit /b 1
)

echo [INFO] Ejecutando dry-run...
python main.py --dry-run
if errorlevel 1 (
    echo [ERROR] Dry-run de hospitality_pipeline fallo.
    pause
    exit /b 1
)

echo [INFO] Ejecutando pipeline completo...
python main.py
if errorlevel 1 (
    echo [ERROR] hospitality_pipeline fallo.
    pause
    exit /b 1
)
echo [OK] hospitality_pipeline completado.
echo.

REM ============================================================
REM  3. RENTABILIDAD PIPELINE
REM ============================================================
echo ============================================================
echo  [3/3] RENTABILIDAD PIPELINE
echo ============================================================
cd /d "%BASE_DIR%rentabilidad_pipeline"

echo [INFO] Instalando dependencias...
pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo [ERROR] Fallo al instalar dependencias de rentabilidad_pipeline
    pause
    exit /b 1
)

echo [INFO] Ejecutando dry-run...
python main.py --dry-run
if errorlevel 1 (
    echo [ERROR] Dry-run de rentabilidad_pipeline fallo.
    pause
    exit /b 1
)

echo [INFO] Ejecutando pipeline completo...
python main.py
if errorlevel 1 (
    echo [ERROR] rentabilidad_pipeline fallo.
    pause
    exit /b 1
)
echo [OK] rentabilidad_pipeline completado.
echo.

REM ============================================================
echo ============================================================
echo  TODOS LOS PIPELINES COMPLETADOS EXITOSAMENTE
echo  %DATE% %TIME%
echo ============================================================
echo.
echo IMPORTANTE: Copia los Dataset IDs del log a los .env de cada pipeline.
echo Los IDs aparecen en el log como: "Dataset ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
echo.
pause
