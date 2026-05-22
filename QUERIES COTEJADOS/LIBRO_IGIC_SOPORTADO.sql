-- ============================================================
-- LIBRO DE IGIC SOPORTADO
-- ------------------------------------------------------------
-- Descripción : Libro de IGIC soportado (compras). Una fila
--               por línea de factura de proveedor con tasa
--               IGIC. Incluye datos de pago y ref. de factura.
-- Parámetros  : [%FechaDesde%] Fecha inicio (YYYY-MM-DD)
--               [%FechaHasta%] Fecha fin    (YYYY-MM-DD)
-- Tablas      : OPCH, PCH1, OCRD, OVTG
-- ============================================================
SELECT
    O."TaxDate"                                  AS "Fecha Contable",
    O."DocNum"                                   AS "Nº Documento",
    COALESCE(O."NumAtCard", '')                  AS "Nº Factura Proveedor",
    O."CardCode"                                 AS "Código Proveedor",
    C."CardName"                                 AS "Proveedor",
    COALESCE(C."LicTradNum", '')                 AS "NIF",
    O."VatGroup"                                 AS "Código IGIC",
    O."VatName"                                  AS "Descripción IGIC",
    O."VatPrcnt"                                 AS "% IGIC",
    SUM(O."LineTotal")                           AS "Base Imponible",
    SUM(O."VatSum")                              AS "Cuota IGIC",
    SUM(O."LineTotal") + SUM(O."VatSum")         AS "Total Factura",
    O."Tipo Doc"
FROM (
    SELECT O."TaxDate", O."DocNum", O."NumAtCard", O."CardCode",
           L."VatGroup", VTG."Name" AS "VatName", L."VatPrcnt",
           L."LineTotal", L."VatSum", 'Factura' AS "Tipo Doc"
    FROM "OPCH" O
    INNER JOIN "PCH1" L   ON O."DocEntry" = L."DocEntry"
    INNER JOIN "OVTG" VTG ON L."VatGroup" = VTG."Code"
    WHERE O."TaxDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND L."VatGroup" LIKE 'IGIC%'
    UNION ALL
    SELECT O."TaxDate", O."DocNum", O."NumAtCard", O."CardCode",
           L."VatGroup", VTG."Name", L."VatPrcnt",
           -L."LineTotal", -L."VatSum", 'Abono'
    FROM "ORPC" O
    INNER JOIN "RPC1" L   ON O."DocEntry" = L."DocEntry"
    INNER JOIN "OVTG" VTG ON L."VatGroup" = VTG."Code"
    WHERE O."TaxDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND L."VatGroup" LIKE 'IGIC%'
) O
INNER JOIN "OCRD" C ON O."CardCode" = C."CardCode"
GROUP BY
    O."TaxDate", O."DocNum", O."NumAtCard", O."CardCode",
    C."CardName", C."LicTradNum", O."VatGroup", O."VatName", O."VatPrcnt", O."Tipo Doc"
ORDER BY O."TaxDate", O."DocNum", O."VatPrcnt";