-- ===========================================================
-- LIBRO IVA SOPORTADO
-- Facturas de compra por fecha contable, desglosadas por tipo IVA
-- Incluye: IVA soportado, Intracomunitario, Importación, Exento
-- Excluye: IGIC (categoría "O")
-- ===========================================================
SELECT
    O."TaxDate"                                  AS "Fecha Contable",
    O."DocNum"                                   AS "Nº Documento",
    COALESCE(O."NumAtCard", '')                  AS "Nº Factura Proveedor",
    O."CardCode"                                 AS "Código Proveedor",
    C."CardName"                                 AS "Proveedor",
    COALESCE(C."LicTradNum", '')                 AS "NIF",
    O."VatGroup"                                 AS "Código IVA",
    O."VatName"                                  AS "Descripción IVA",
    O."VatPrcnt"                                 AS "% IVA",
    SUM(O."LineTotal")                           AS "Base Imponible",
    SUM(O."VatSum")                              AS "Cuota IVA",
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
    AND VTG."Category" = 'I' AND L."VatGroup" NOT LIKE 'IGIC%'
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
    AND VTG."Category" = 'I' AND L."VatGroup" NOT LIKE 'IGIC%'
) O
INNER JOIN "OCRD" C ON O."CardCode" = C."CardCode"
GROUP BY
    O."TaxDate", O."DocNum", O."NumAtCard", O."CardCode",
    C."CardName", C."LicTradNum", O."VatGroup", O."VatName", O."VatPrcnt", O."Tipo Doc"
ORDER BY O."TaxDate", O."DocNum", O."VatPrcnt";