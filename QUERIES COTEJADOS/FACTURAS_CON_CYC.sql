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
    C."CreditLine"                           AS "Límite CYC",
    V."DocTotal"                             AS "Importe",
    V."DocNum"                               AS "Numero Factura",
    V."CardCode"                             AS "Cliente",
    'FACTURA'                                AS "Tipo"

FROM "OINV" V
JOIN "OCRD" C
  ON V."CardCode" = C."CardCode"

WHERE
    V."DocDate" >= TO_DATE(SUBSTR('[%FechaDesde%]', 1, 10), 'YYYY-MM-DD')
    AND V."DocDate" <= TO_DATE(SUBSTR('[%FechaHasta%]', 1, 10), 'YYYY-MM-DD')
    AND C."CreditLine" > 0

UNION ALL

-- ABONOS / DEVOLUCIONES (ORIN en negativo)
SELECT
    TO_VARCHAR(V."DocDueDate", 'DD/MM/YYYY'),
    TO_VARCHAR(V."DocDate",    'DD/MM/YYYY'),
    C."CardName",
    C."LicTradNum",
    C."CreditLine",
    -V."DocTotal",
    V."DocNum",
    V."CardCode",
    'ABONO'

FROM "ORIN" V
JOIN "OCRD" C
  ON V."CardCode" = C."CardCode"

WHERE
    V."DocDate" >= TO_DATE(SUBSTR('[%FechaDesde%]', 1, 10), 'YYYY-MM-DD')
    AND V."DocDate" <= TO_DATE(SUBSTR('[%FechaHasta%]', 1, 10), 'YYYY-MM-DD')
    AND C."CreditLine" > 0

ORDER BY
    "Fecha Factura",
    "Cliente",
    "Numero Factura";
