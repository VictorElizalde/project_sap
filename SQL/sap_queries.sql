/********************************************************************************************
    PACK DE QUERIES SAP - CONSULTAS FRECUENTES EMPRESA
    Autor: Victor Hugo + GPT-5
    Fecha: 2025-11-05
    Descripción:
    Consultas base para informes financieros, logísticos y de gestión en SAP B1 / ECC
********************************************************************************************/

---------------------------------------
-- VARIABLES GENERALES
---------------------------------------
DECLARE @FechaConsulta DATE = '2025-10-31';
DECLARE @FechaInicio DATE = '2025-10-01';
DECLARE @FechaFin DATE = '2025-10-31';
DECLARE @Proveedor NVARCHAR(50) = 'P0001';
DECLARE @Albaran INT = 12345;
DECLARE @Mes INT = 10;
DECLARE @Año INT = 2025;

---------------------------------------------------------------------------------------------
-- 1. INVENTARIO (Stock por fecha)
---------------------------------------------------------------------------------------------
SELECT 
    I.ItemCode,
    I.ItemName,
    W.WhsCode,
    W.WhsName,
    SUM(IT.InQty - IT.OutQty) AS Stock,
    @FechaConsulta AS Fecha
FROM OINM IT
JOIN OITM I ON IT.ItemCode = I.ItemCode
JOIN OWHS W ON IT.WhsCode = W.WhsCode
WHERE IT.DocDate <= @FechaConsulta
GROUP BY I.ItemCode, I.ItemName, W.WhsCode, W.WhsName
ORDER BY I.ItemCode;


---------------------------------------------------------------------------------------------
-- 2. LISTADO DE ALBARANES CLIENTES (por día)
---------------------------------------------------------------------------------------------
SELECT 
    D.DocNum AS Albaran,
    D.DocDate,
    C.CardCode,
    C.CardName,
    L.ItemCode,
    L.Dscription,
    L.Quantity,
    L.WhsCode
FROM ODLN D
JOIN DLN1 L ON D.DocEntry = L.DocEntry
JOIN OCRD C ON D.CardCode = C.CardCode
WHERE D.DocDate = @FechaConsulta
ORDER BY D.DocNum;


---------------------------------------------------------------------------------------------
-- 3. DEUDA CLIENTES (facturas abiertas)
---------------------------------------------------------------------------------------------
SELECT
    "DocEntry", "DocNum", "DocDate", "DocDueDate", "DocTotal", "PaidToDate", "CardCode"
FROM "OPCH"
ORDER BY "DocDate" DESC;


---------------------------------------------------------------------------------------------
-- 4. DEUDA PROVEEDORES
---------------------------------------------------------------------------------------------
SELECT 
    P.CardCode,
    P.CardName,
    F.DocNum,
    F.DocDate,
    F.DocDueDate,
    F.DocTotal - F.PaidToDate AS SaldoPendiente
FROM OPCH F
JOIN OCRD P ON F.CardCode = P.CardCode
WHERE F.DocTotal > F.PaidToDate
  AND F.DocDate <= @FechaConsulta
ORDER BY P.CardName;


---------------------------------------------------------------------------------------------
-- 5. VENTAS CATALONIA (por rango de fechas y agrupación)
---------------------------------------------------------------------------------------------
SELECT 
    C.CardCode,
    C.CardName,
    L.ItemCode,
    L.Dscription,
    SUM(L.Quantity) AS Cantidad,
    SUM(L.LineTotal) AS Total
FROM OINV V
JOIN INV1 L ON V.DocEntry = L.DocEntry
JOIN OCRD C ON V.CardCode = C.CardCode
WHERE V.DocDate BETWEEN @FechaInicio AND @FechaFin
  AND C.GroupCode IN (SELECT GroupCode FROM OCRG WHERE GroupName = 'CATALONIA')
GROUP BY C.CardCode, C.CardName, L.ItemCode, L.Dscription
ORDER BY C.CardName;


---------------------------------------------------------------------------------------------
-- 6. INFORME C&C (por mes)
---------------------------------------------------------------------------------------------
SELECT 
    MONTH(V.DocDate) AS Mes,
    YEAR(V.DocDate) AS Año,
    SUM(V.DocTotal) AS TotalVentas,
    COUNT(V.DocNum) AS NumFacturas
FROM OINV V
WHERE MONTH(V.DocDate) = @Mes
  AND YEAR(V.DocDate) = @Año
GROUP BY MONTH(V.DocDate), YEAR(V.DocDate);


---------------------------------------------------------------------------------------------
-- 7. COMPRAS POR FAMILIA / ARTÍCULO (por proveedor)
---------------------------------------------------------------------------------------------
SELECT
    P."CardCode"   AS "CardCode",
    P."CardName"   AS "CardName",
    G."ItmsGrpNam" AS "Familia",
    L."ItemCode"   AS "ItemCode",
    L."Dscription" AS "Dscription",
    SUM(L."Quantity")  AS "Cantidad",
    SUM(L."LineTotal") AS "Total"
FROM "OPCH" H
         JOIN "PCH1" L ON H."DocEntry" = L."DocEntry"
         JOIN "OCRD" P ON H."CardCode" = P."CardCode"
         LEFT JOIN "OITM" I ON L."ItemCode" = I."ItemCode"
         LEFT JOIN "OITB" G ON I."ItmsGrpCod" = G."ItmsGrpCod"
WHERE H."CardCode" = 'P0001'
  AND H."DocDate" BETWEEN DATE '2025-10-01' AND DATE '2025-10-31'
GROUP BY P."CardCode", P."CardName", G."ItmsGrpNam", L."ItemCode", L."Dscription"
ORDER BY G."ItmsGrpNam", L."ItemCode";

---------------------------------------------------------------------------------------------
-- 8. ESTADÍSTICAS VENTAS (con dirección de entrega)
---------------------------------------------------------------------------------------------
SELECT
    V."DocNum"          AS "DocNum",
    V."DocDate"         AS "DocDate",
    C."CardName"        AS "CardName",
    V."Address2"        AS "DireccionEntrega",
    L."ItemCode"        AS "ItemCode",
    L."Dscription"      AS "Dscription",
    L."Quantity"        AS "Quantity",
    L."LineTotal"       AS "LineTotal",
    (L."LineTotal" - COALESCE(L."TotalSumSy", 0)) AS "Margen"
FROM "OINV" V
         JOIN "INV1" L ON V."DocEntry" = L."DocEntry"
         JOIN "OCRD" C ON V."CardCode" = C."CardCode"
WHERE V."DocDate" BETWEEN DATE '2025-10-01' AND DATE '2025-10-31'
ORDER BY V."DocDate", V."DocNum";


---------------------------------------------------------------------------------------------
-- 9. EXCEL LOGÍSTICA (Vivace)
---------------------------------------------------------------------------------------------
SELECT
    D."DocNum"        AS "DocNum",
    D."DocDate"       AS "DocDate",
    D."CardCode"      AS "CardCode",
    D."CardName"      AS "CardName",
    L."ItemCode"      AS "ItemCode",
    L."Dscription"    AS "Dscription",
    L."Quantity"      AS "Quantity",
    L."WhsCode"       AS "WhsCode",
    D."Address2"      AS "DireccionEntrega"
FROM "ODLN" D
         JOIN "DLN1" L ON D."DocEntry" = L."DocEntry"
WHERE D."DocNum" = 12345
ORDER BY L."LineNum";


---------------------------------------------------------------------------------------------
-- 10. CUENTAS CON MOVIMIENTOS POR MES
---------------------------------------------------------------------------------------------
-- Parámetros: usar DATE 'YYYY-MM-DD'
-- ejemplo para octubre 2025:
-- fecha_inicio = DATE '2025-10-01'
-- fecha_fin_excl = DATE '2025-11-01'

SELECT
    A."AcctCode"   AS "AcctCode",
    A."AcctName"   AS "AcctName",
    SUM(J."Debit" - J."Credit") AS "MovimientoMes"
FROM "OJDT" T
         JOIN "JDT1" J ON T."TransId" = J."TransId"
         JOIN "OACT" A ON J."Account" = A."AcctCode"
WHERE T."RefDate" >= DATE '2025-10-01'   -- inclusive
  AND T."RefDate" <  DATE '2025-11-01'   -- exclusive: primer dia mes siguiente
GROUP BY A."AcctCode", A."AcctName"
ORDER BY A."AcctCode";


---------------------------------------------------------------------------------------------
-- 11. PyG (Pérdidas y Ganancias)
---------------------------------------------------------------------------------------------
-- Parámetros: usar DATE 'YYYY-MM-DD'
-- ejemplo para octubre 2025:
-- fecha_inicio = DATE '2025-10-01'
-- fecha_fin_excl = DATE '2025-11-01'

SELECT
    A."AcctCode"   AS "AcctCode",
    A."AcctName"   AS "AcctName",
    SUM(J."Debit" - J."Credit") AS "MovimientoMes"
FROM "OJDT" T
         JOIN "JDT1" J ON T."TransId" = J."TransId"
         JOIN "OACT" A ON J."Account" = A."AcctCode"
GROUP BY A."AcctCode", A."AcctName"
ORDER BY A."AcctCode";


---------------------------------------------------------------------------------------------
-- 12. BALANCE
---------------------------------------------------------------------------------------------
-- Balance por año (ej: 2025)
SELECT
    A."AcctCode"   AS "AcctCode",
    A."AcctName"   AS "AcctName",
    SUM(J."Debit" - J."Credit") AS "Saldo"
FROM "JDT1" J
         JOIN "OACT" A ON J."Account" = A."AcctCode"
WHERE J."RefDate" >= DATE '2025-01-01'
  AND J."RefDate" <  DATE '2026-01-01'
GROUP BY A."AcctCode", A."AcctName"
ORDER BY A."AcctCode";


---------------------------------------------------------------------------------------------
-- 13. SUMAS Y SALDOS
---------------------------------------------------------------------------------------------
-- Sumas y Saldos por año (ejemplo 2025)
SELECT
    A."AcctCode"   AS "AcctCode",
    A."AcctName"   AS "AcctName",
    SUM(J."Debit")  AS "TotalDebe",
    SUM(J."Credit") AS "TotalHaber",
    SUM(J."Debit" - J."Credit") AS "Saldo"
FROM "JDT1" J
         JOIN "OACT" A ON J."Account" = A."AcctCode"
WHERE J."RefDate" >= DATE '2025-01-01'
  AND J."RefDate" <  DATE '2026-01-01'
GROUP BY A."AcctCode", A."AcctName"
ORDER BY A."AcctCode";

---------------------------------------------------------------------------------------------
-- 14. ARTÍCULOS CON CANON DIGITAL
---------------------------------------------------------------------------------------------
-- Parámetros (si prefieres sustituirlos manualmente, cambia las fechas aquí)
-- FechaInicio = '2025-10-01', FechaFin = '2025-10-31'

SELECT
    I."ItemCode"    AS ItemCode,
    I."ItemName"    AS ItemName,
    SUM(L."Quantity")   AS Cantidad,
    SUM(L."LineTotal")  AS Total
FROM "OINV" V
         JOIN "INV1" L   ON V."DocEntry" = L."DocEntry"
         JOIN "OITM" I   ON L."ItemCode" = I."ItemCode"
WHERE I."U_GEI_Canon" = 'Y'   -- <- campo correcto según metadata
  AND V."DocDate" BETWEEN DATE '2025-01-01' AND DATE '2026-10-31'
GROUP BY I."ItemCode", I."ItemName"
ORDER BY I."ItemCode";


---------------------------------------------------------------------------------------------
-- 15. LIBRO DE IVA SOPORTADO Y REPERCUTIDO
---------------------------------------------------------------------------------------------

-- IVA REPERCUTIDO (ventas)
-- Ejemplo HANA: IVA repercutido (ventas) por línea
-- Sustituye las fechas por tus valores
SELECT
    V."DocNum"        AS DocNum,
    V."DocDate"       AS DocDate,
    C."CardName"      AS CardName,
    T."Rate"          AS IVA,
    L."LineTotal"     AS BaseImponible,
    (L."LineTotal" * T."Rate" / 100) AS IVAImporte
FROM "OINV" V
         JOIN "INV1" L ON V."DocEntry" = L."DocEntry"
         LEFT JOIN "OCRD" C ON V."CardCode" = C."CardCode"
         LEFT JOIN "OVTG" T ON L."VatGroup" = T."Code"
WHERE V."DocDate" BETWEEN DATE '2025-10-01' AND DATE '2025-10-31'
ORDER BY V."DocDate", V."DocNum", L."LineNum";



---------------------------------------------------------------------------------------------
-- 16. LIBRO DE IGIC SOPORTADO Y REPERCUTIDO
---------------------------------------------------------------------------------------------
-- IGIC repercutido - agrupado por tasa
SELECT
    T."Rate"   AS IGIC,
    SUM(L."LineTotal") AS BaseTotal,
    SUM(L."LineTotal" * T."Rate" / 100) AS IVA_Total
FROM "OINV" V
         JOIN "INV1" L ON V."DocEntry" = L."DocEntry"
         LEFT JOIN "OVTG" T ON L."VatGroup" = T."Code"
WHERE T."Name" LIKE '%IGIC%'
  AND V."DocDate" BETWEEN DATE '2025-10-01' AND DATE '2025-10-31'
GROUP BY T."Rate"
ORDER BY T."Rate";

-- IGIC soportado - agrupado por tasa
SELECT
    T."Rate"   AS IGIC,
    SUM(L."LineTotal") AS BaseTotal,
    SUM(L."LineTotal" * T."Rate" / 100) AS IVA_Total
FROM "OPCH" C
         JOIN "PCH1" L ON C."DocEntry" = L."DocEntry"
         LEFT JOIN "OVTG" T ON L."VatGroup" = T."Code"
WHERE T."Name" LIKE '%IGIC%'
  AND C."DocDate" BETWEEN DATE '2025-10-01' AND DATE '2025-10-31'
GROUP BY T."Rate"
ORDER BY T."Rate";

