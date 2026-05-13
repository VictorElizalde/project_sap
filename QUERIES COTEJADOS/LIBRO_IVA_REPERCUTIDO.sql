-- ============================================================
-- LIBRO IVA REPERCUTIDO
-- ------------------------------------------------------------
-- Descripción : Libro de IVA repercutido (ventas). Una fila
--               por factura de cliente y tipo impositivo.
--               Calcula base imponible, cuota y total agrupados.
-- Parámetros  : [%FechaDesde%] Fecha inicio (YYYY-MM-DD)
--               [%FechaHasta%] Fecha fin    (YYYY-MM-DD)
-- Tablas      : OINV, INV1, OCRD, OVTG
-- ============================================================
SELECT
    ROW_NUMBER() OVER (ORDER BY "Fecha Contable", "DOCUM", "IVA TIPO") AS "N.REGISTRO",
    "Fecha Contable" AS "FECHA",
    "NIF/DNI", "NOMBRE", "BASE", "IVA TIPO", "CUOTA", "TOTAL",
    "DOCUM", "F/A", "N/E", "Tipo AUT", "Env/SII"
FROM (
    SELECT
        O."TaxDate" AS "Fecha Contable", COALESCE(C."LicTradNum",'') AS "NIF/DNI",
        C."CardName" AS "NOMBRE", SUM(L."LineTotal") AS "BASE", L."VatPrcnt" AS "IVA TIPO",
        SUM(L."VatSum") AS "CUOTA", SUM(L."LineTotal")+SUM(L."VatSum") AS "TOTAL",
        O."DocNum" AS "DOCUM", 'F' AS "F/A",
        CASE WHEN C."Country"='ES' THEN 'N' ELSE 'E' END AS "N/E",
        COALESCE(O."AuthCode",'') AS "Tipo AUT", COALESCE(O."U_GEI_Env",'') AS "Env/SII"
    FROM "OINV" O
    INNER JOIN "INV1" L ON O."DocEntry"=L."DocEntry"
    INNER JOIN "OCRD" C ON O."CardCode"=C."CardCode"
    INNER JOIN "OVTG" VTG ON L."VatGroup"=VTG."Code"
    WHERE O."TaxDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND VTG."Category"='O' AND L."VatGroup" NOT LIKE 'IGIC%'
    GROUP BY O."TaxDate",O."DocNum",C."LicTradNum",C."CardName",C."Country",L."VatPrcnt",O."AuthCode",O."U_GEI_Env"
    UNION ALL
    SELECT
        O."TaxDate", COALESCE(C."LicTradNum",''), C."CardName",
        SUM(L."LineTotal"), L."VatPrcnt", SUM(L."VatSum"), SUM(L."LineTotal")+SUM(L."VatSum"),
        O."DocNum", 'F', CASE WHEN C."Country"='ES' THEN 'N' ELSE 'E' END,
        COALESCE(O."AuthCode",''), COALESCE(O."U_GEI_Env",'')
    FROM "ODPI" O
    INNER JOIN "DPI1" L ON O."DocEntry"=L."DocEntry"
    INNER JOIN "OCRD" C ON O."CardCode"=C."CardCode"
    INNER JOIN "OVTG" VTG ON L."VatGroup"=VTG."Code"
    WHERE O."TaxDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND VTG."Category"='O' AND L."VatGroup" NOT LIKE 'IGIC%'
    GROUP BY O."TaxDate",O."DocNum",C."LicTradNum",C."CardName",C."Country",L."VatPrcnt",O."AuthCode",O."U_GEI_Env"
    UNION ALL
    SELECT
        O."TaxDate", COALESCE(C."LicTradNum",''), C."CardName",
        -SUM(L."LineTotal"), L."VatPrcnt", -SUM(L."VatSum"), -(SUM(L."LineTotal")+SUM(L."VatSum")),
        O."DocNum", 'A', CASE WHEN C."Country"='ES' THEN 'N' ELSE 'E' END,
        COALESCE(O."AuthCode",''), COALESCE(O."U_GEI_Env",'')
    FROM "ORIN" O
    INNER JOIN "RIN1" L ON O."DocEntry"=L."DocEntry"
    INNER JOIN "OCRD" C ON O."CardCode"=C."CardCode"
    INNER JOIN "OVTG" VTG ON L."VatGroup"=VTG."Code"
    WHERE O."TaxDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND VTG."Category"='O' AND L."VatGroup" NOT LIKE 'IGIC%'
    GROUP BY O."TaxDate",O."DocNum",C."LicTradNum",C."CardName",C."Country",L."VatPrcnt",O."AuthCode",O."U_GEI_Env"
) T
ORDER BY "Fecha Contable", "DOCUM", "IVA TIPO";