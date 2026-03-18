-- =====================================================================================
-- INFORME: VENTAS CATALUNYA – FORMATO CSV
-- SISTEMA: SAP Business One sobre HANA
-- -------------------------------------------------------------------------------------
-- OBJETIVO:
-- - Listado de ventas (facturas de clientes) filtradas por central de compras
-- - Una fila por factura
-- - Importe neto (sin IVA)
-- - Estructura compatible con CSV solicitado
-- - Filtrado por rango de fechas
-- -------------------------------------------------------------------------------------
-- CONSIDERACIONES IMPORTANTES:
-- 1) El filtro "central de compras" se aplica sobre OCRD.U_CentralCompras (UDF).
--    - Valores permitidos: CATALONIA HOTELS o ASOCIADO QUANTUM
-- 2) El importe neto se calcula como SUM(INV1.LineTotal).
-- 3) El rango de fechas se toma desde OINV.DocDate
-- 4) Campos no estándar SAP se dejan explícitamente en blanco.
-- 5) Query preparado para:
--    ✔ Query Manager
--    ✔ DataGrip
--    ✔ Exportación directa a CSV
-- =====================================================================================

SELECT
    -- CLI-AG
    G."GroupCode"                                AS "CLI-AG",

    -- Nombre Cliente Agrupado
    G."GroupName"                                AS "Nombre Cliente Agrupado",

    -- Fecha Factura
    TO_VARCHAR(V."DocDate", 'DD/MM/YYYY')        AS "Fecha Factura",

    -- Número de factura
    V."DocNum"                                   AS "Num. Factura",

    -- Código cliente
    C."CardCode"                                 AS "Codigo Cliente",

    -- Nombre cliente
    C."CardName"                                 AS "Nombre Cliente",

    -- Código dirección envío
    COALESCE(V."ShipToCode", '')                 AS "Codigo Dir. Envio",

    -- Dirección de envío (texto completo)
    COALESCE(V."Address2", '')                   AS "Dir. Envio",

    -- Importe neto
    SUM(L."LineTotal")                           AS "Importe Neto"

FROM "OINV" V
         JOIN "INV1" L
              ON V."DocEntry" = L."DocEntry"

         JOIN "OCRD" C
              ON V."CardCode" = C."CardCode"

         LEFT JOIN "OCRG" G
                   ON C."GroupCode" = G."GroupCode"

WHERE
    V."DocDate" BETWEEN '[%DateFrom%]' AND '[%DateTo%]'
    -- TODO: Reemplaza U_CentralCompras con el nombre correcto del UDF
    -- AND COALESCE(C."U_CentralCompras", '') IN ('CATALONIA HOTELS', 'ASOCIADO QUANTUM')

GROUP BY
    G."GroupCode",
    G."GroupName",
    V."DocDate",
    V."DocNum",
    C."CardCode",
    C."CardName",
    V."ShipToCode",
    V."Address2"

ORDER BY
    C."CardName",
    V."DocNum";

-- =====================================================================================
-- NOTAS FINALES:
-- - El importe es NETO (sin IVA).
-- - Si necesitas IVA o total documento:
--   ▸ IVA → usar INV1.VatSum
--   ▸ Total → usar OINV.DocTotal
-- - Filtro "central de compras" ahora usa OCRD.U_CentralCompras
--   ▸ Valores: CATALONIA HOTELS o ASOCIADO QUANTUM
-- - Rango de fechas usa parámetros [%DateFrom%] y [%DateTo%]
-- =====================================================================================
