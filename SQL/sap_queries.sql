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
-- Ejemplo HANA: DeliveryNotes lines + campos desde Orders cuando exista BaseEntry
-- Query para SAP HANA / SAP B1 que genera las columnas del CSV solicitado
SELECT
    COALESCE(o.Reference1, d.Reference1, TO_VARCHAR(o.DocNum))                                  AS "Código Pedido",     -- Reference1 del pedido o fallback DocNum
    TO_VARCHAR(o.DocDate,'DD/MM/YYYY')                                                             AS "Fecha Pedido",
    TO_VARCHAR(d.DocNum)                                                                          AS "Núm.Albarán",
    TO_VARCHAR(d.DocDate,'DD/MM/YYYY')                                                             AS "Fecha Albarán",
    COALESCE(d.Reference2, '')                                                                     AS "Expediente",
    d.CardCode                                                                                    AS "Código destinatario",
    d.CardName                                                                                     AS "Nombre destinatario",
    COALESCE(d.Address2, d.Address, o.Address)                                                     AS "Dirección destinatario",
    COALESCE(odx.ShipToZipCode, ttx.ZipCodeS, '')                                                  AS "C.Postal destinatario",  -- ver notas
    COALESCE(odx.ShipToCity, ttx.CityS, '')                                                        AS "Población destinatario",
    COALESCE(odx.ShipToCounty, ttx.CountyS, '')                                                    AS "Provincia destinatario",
    COALESCE(odx.ShipToCountry, ttx.CountryS, '')                                                  AS "País destinatario",
    COALESCE(d.FederalTaxID, o.FederalTaxID, c.FederalTaxID, '')                                   AS "CIF destinatario",
    COALESCE(d.Phone1, o.Phone1, c.Phone1, '')                                                      AS "Teléfono destinatario",
    COALESCE(d.Comments, o.Comments, '')                                                            AS "Obs.destinatario",
    CASE
        WHEN UPPER(COALESCE(l.ItemCode,'') ) LIKE '%PORTES%' THEN COALESCE(l.LineTotal, l.Price, 0)
        ELSE NULL
        END                                                                                             AS "Portes",
    COALESCE(ttx.BoEValue, '')                                                                      AS "Valor Asegurado",        -- posible campo en TaxExtension
    ''                                                                                              AS "Albarán valorado",
    COALESCE(ttx.Carrier, '')                                                                       AS "Transportista",
    COALESCE(ttx.Vehicle, '')                                                                       AS "Servicio transportista",
    l.LineNum                                                                                        AS "Línia comanda",
    COALESCE(l.ItemCode, '')                                                                         AS "Código artículo",
    COALESCE(l.ItemDescription, l.Dscription, '')                                                    AS "Descripción",
    TO_DECIMAL(COALESCE(l.Quantity,0), 19, 6)                                                         AS "Cantidad",
    COALESCE(l.Weight1, l.Weight2, 0)                                                                AS "Peso",
    COALESCE(
            NULLIF(LTRIM(RTRIM(COALESCE(odx.ShipToEMail, odx.BillToEMail, o.AddressExtension_ShipToEMail, c.E_Mail))), ''),
            ''
    )                                                                                                AS "e-mail",
    COALESCE(o.NumAtCard, d.NumAtCard, '')                                                            AS "S/Referencia Pedido",
    COALESCE(d.Comments, o.Comments, '')                                                              AS "Observaciones externas",
    COALESCE(l.FreeText, '')                                                                          AS "Observaciones almacen",
    COALESCE(d.BPLName, o.BPLName, '')                                                                AS "Datos empresa"
FROM ODLN d
         LEFT JOIN DLN1 l         ON d.DocEntry = l.DocEntry
         LEFT JOIN ORDR o         ON o.DocNum = d.DocNum        -- unión por DocNum como solicitaste
         LEFT JOIN OCRD c         ON d.CardCode = c.CardCode
-- A continuación: lecturas desde tablas de extensión o vistas (puede que necesites adaptarlas)
         LEFT JOIN "YOUR_SCHEMA"."ODLN_ADDRESS_EXTENSION" odx ON odx.DocEntry = d.DocEntry    -- Ejemplo: si tú tienes una vista/tab extensión
         LEFT JOIN "YOUR_SCHEMA"."ODLN_TAX_EXTENSION" ttx     ON ttx.DocEntry = d.DocEntry     -- Ejemplo TaxExtension
WHERE d.DocNum = :P_NUMALBARAN                         -- parámetro; o quítalo para rango
-- AND d.DocumentStatus = 'bost_Open'                -- si quieres filtrar por estado (open/close)
ORDER BY d.DocNum, l.LineNum;

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

