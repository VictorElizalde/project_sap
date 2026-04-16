-- ============================================================
-- FACTURAS CON CYC
-- ------------------------------------------------------------
-- Descripción : Facturas de clientes no cerradas en un rango
--               de fechas. Incluye NIF, importe, vencimiento
--               y número de factura.
-- Parámetros  : [%FechaDesde%] Fecha inicio (YYYY-MM-DD)
--               [%FechaHasta%] Fecha fin    (YYYY-MM-DD)
-- Tablas      : OINV, OCRD
-- ============================================================
SELECT
    TO_VARCHAR(V."DocDueDate", 'DD/MM/YYYY') AS "Vencimiento",
    TO_VARCHAR(V."DocDate",    'DD/MM/YYYY') AS "Fecha Factura",
    C."CardName"                             AS "Razón Fiscal",
    C."LicTradNum"                           AS "NIF",
    V."DocTotal"                             AS "Importe",
    V."DocNum"                               AS "Numero Factura",
    V."CardCode"                             AS "Cliente"
FROM "OINV" V
JOIN "OCRD" C
  ON V."CardCode" = C."CardCode"
WHERE
    V."DocDate" >= TO_DATE('[%FechaDesde%]', 'YYYY-MM-DD')
    AND V."DocDate" <= TO_DATE('[%FechaHasta%]', 'YYYY-MM-DD')
    AND V."DocStatus" <> 'C'
ORDER BY
    V."DocDate",
    V."DocNum";
