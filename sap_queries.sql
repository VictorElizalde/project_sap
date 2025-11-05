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
    C.CardCode,
    C.CardName,
    F.DocNum,
    F.DocDate,
    F.DocDueDate,
    F.DocTotal - F.PaidToDate AS SaldoPendiente
FROM OINV F
JOIN OCRD C ON F.CardCode = C.CardCode
WHERE F.DocTotal > F.PaidToDate
  AND F.DocDate <= @FechaConsulta
ORDER BY C.CardName;


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
    P.CardCode,
    P.CardName,
    I.ItmsGrpNam AS Familia,
    L.ItemCode,
    L.Dscription,
    SUM(L.Quantity) AS Cantidad,
    SUM(L.LineTotal) AS Total
FROM OPCH C
JOIN PCH1 L ON C.DocEntry = L.DocEntry
JOIN OCRD P ON C.CardCode = P.CardCode
JOIN OITM I ON L.ItemCode = I.ItemCode
WHERE C.CardCode = @Proveedor
  AND C.DocDate BETWEEN @FechaInicio AND @FechaFin
GROUP BY P.CardCode, P.CardName, I.ItmsGrpNam, L.ItemCode, L.Dscription
ORDER BY I.ItmsGrpNam, L.ItemCode;


---------------------------------------------------------------------------------------------
-- 8. ESTADÍSTICAS VENTAS (con dirección de entrega)
---------------------------------------------------------------------------------------------
SELECT 
    V.DocNum,
    V.DocDate,
    C.CardName,
    V.Address2 AS DireccionEntrega,
    L.ItemCode,
    L.Dscription,
    L.Quantity,
    L.LineTotal,
    (L.LineTotal - L.TotalSumSy) AS Margen
FROM OINV V
JOIN INV1 L ON V.DocEntry = L.DocEntry
JOIN OCRD C ON V.CardCode = C.CardCode
WHERE V.DocDate BETWEEN @FechaInicio AND @FechaFin
ORDER BY V.DocDate, V.DocNum;


---------------------------------------------------------------------------------------------
-- 9. EXCEL LOGÍSTICA (Vivace)
---------------------------------------------------------------------------------------------
SELECT 
    D.DocNum,
    D.DocDate,
    D.CardCode,
    D.CardName,
    L.ItemCode,
    L.Dscription,
    L.Quantity,
    L.WhsCode,
    D.Address2 AS DireccionEntrega
FROM ODLN D
JOIN DLN1 L ON D.DocEntry = L.DocEntry
WHERE D.DocNum = @Albaran
ORDER BY L.LineNum;


---------------------------------------------------------------------------------------------
-- 10. CUENTAS CON MOVIMIENTOS POR MES
---------------------------------------------------------------------------------------------
SELECT 
    A.AcctCode,
    A.AcctName,
    SUM(J.Debit - J.Credit) AS MovimientoMes
FROM OJDT T
JOIN JDT1 J ON T.TransId = J.TransId
JOIN OACT A ON J.Account = A.AcctCode
WHERE MONTH(T.RefDate) = @Mes AND YEAR(T.RefDate) = @Año
GROUP BY A.AcctCode, A.AcctName
ORDER BY A.AcctCode;


---------------------------------------------------------------------------------------------
-- 11. PyG (Pérdidas y Ganancias)
---------------------------------------------------------------------------------------------
SELECT 
    A.FinanseAct,
    SUM(J.Debit - J.Credit) AS Monto
FROM JDT1 J
JOIN OACT A ON J.Account = A.AcctCode
WHERE YEAR(J.RefDate) = @Año
GROUP BY A.FinanseAct;


---------------------------------------------------------------------------------------------
-- 12. BALANCE
---------------------------------------------------------------------------------------------
SELECT 
    A.AcctCode,
    A.AcctName,
    SUM(J.Debit - J.Credit) AS Saldo
FROM JDT1 J
JOIN OACT A ON J.Account = A.AcctCode
WHERE YEAR(J.RefDate) = @Año
GROUP BY A.AcctCode, A.AcctName
ORDER BY A.AcctCode;


---------------------------------------------------------------------------------------------
-- 13. SUMAS Y SALDOS
---------------------------------------------------------------------------------------------
SELECT 
    A.AcctCode,
    A.AcctName,
    SUM(J.Debit) AS TotalDebe,
    SUM(J.Credit) AS TotalHaber,
    SUM(J.Debit - J.Credit) AS Saldo
FROM JDT1 J
JOIN OACT A ON J.Account = A.AcctCode
WHERE YEAR(J.RefDate) = @Año
GROUP BY A.AcctCode, A.AcctName
ORDER BY A.AcctCode;


---------------------------------------------------------------------------------------------
-- 14. ARTÍCULOS CON CANON DIGITAL
---------------------------------------------------------------------------------------------
SELECT 
    I.ItemCode,
    I.ItemName,
    SUM(L.Quantity) AS Cantidad,
    SUM(L.LineTotal) AS Total
FROM OINV V
JOIN INV1 L ON V.DocEntry = L.DocEntry
JOIN OITM I ON L.ItemCode = I.ItemCode
WHERE I.U_CanonDigital = 'Y'
  AND V.DocDate BETWEEN @FechaInicio AND @FechaFin
GROUP BY I.ItemCode, I.ItemName;


---------------------------------------------------------------------------------------------
-- 15. LIBRO DE IVA SOPORTADO Y REPERCUTIDO
---------------------------------------------------------------------------------------------

-- IVA REPERCUTIDO (ventas)
SELECT 
    V.DocNum,
    V.DocDate,
    C.CardName,
    T.Rate AS IVA,
    L.LineTotal AS BaseImponible,
    (L.LineTotal * T.Rate / 100) AS IVAImporte
FROM OINV V
JOIN INV1 L ON V.DocEntry = L.DocEntry
JOIN OCRD C ON V.CardCode = C.CardCode
JOIN OVTG T ON L.VatGroup = T.Code
WHERE V.DocDate BETWEEN @FechaInicio AND @FechaFin;

-- IVA SOPORTADO (compras)
SELECT 
    C.DocNum,
    C.DocDate,
    P.CardName,
    T.Rate AS IVA,
    L.LineTotal AS BaseImponible,
    (L.LineTotal * T.Rate / 100) AS IVAImporte
FROM OPCH C
JOIN PCH1 L ON C.DocEntry = L.DocEntry
JOIN OCRD P ON C.CardCode = P.CardCode
JOIN OVTG T ON L.VatGroup = T.Code
WHERE C.DocDate BETWEEN @FechaInicio AND @FechaFin;


---------------------------------------------------------------------------------------------
-- 16. LIBRO DE IGIC SOPORTADO Y REPERCUTIDO
---------------------------------------------------------------------------------------------

-- IGIC REPERCUTIDO (ventas)
SELECT 
    V.DocNum,
    V.DocDate,
    C.CardName,
    T.Rate AS IGIC,
    L.LineTotal AS BaseImponible,
    (L.LineTotal * T.Rate / 100) AS IGICImporte
FROM OINV V
JOIN INV1 L ON V.DocEntry = L.DocEntry
JOIN OCRD C ON V.CardCode = C.CardCode
JOIN OVTG T ON L.VatGroup = T.Code
WHERE T.Name LIKE '%IGIC%' 
  AND V.DocDate BETWEEN @FechaInicio AND @FechaFin;

-- IGIC SOPORTADO (compras)
SELECT 
    C.DocNum,
    C.DocDate,
    P.CardName,
    T.Rate AS IGIC,
    L.LineTotal AS BaseImponible,
    (L.LineTotal * T.Rate / 100) AS IGICImporte
FROM OPCH C
JOIN PCH1 L ON C.DocEntry = L.DocEntry
JOIN OCRD P ON C.CardCode = P.CardCode
JOIN OVTG T ON L.VatGroup = T.Code
WHERE T.Name LIKE '%IGIC%' 
  AND C.DocDate BETWEEN @FechaInicio AND @FechaFin;
