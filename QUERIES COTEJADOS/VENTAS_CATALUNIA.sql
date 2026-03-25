-- ============================================================
-- VENTAS CATALUNIA
-- ------------------------------------------------------------
-- Descripción : Ventas agrupadas por cliente para las centrales
--               de compras «CATALONIA HOTELS» y
--               «ASOCIADO QUANTUM», en un rango de fechas.
-- Parámetros  : [%DateFrom%] Fecha inicio (DD/MM/YYYY)
--               [%DateTo%]   Fecha fin    (DD/MM/YYYY)
-- Tablas      : OINV, INV1, OCRD, OCRG, @GEI_CENTCOMP
-- ============================================================
SELECT
    -- CLI-AG
    G."GroupCode"                                AS "CLI-AG",

    -- Nombre Cliente Agrupado
    G."GroupName"                                AS "Nombre Cliente Agrupado",

    -- Central de Compras
    CC."Name"                                    AS "Central de Compras",

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

         LEFT JOIN "@GEI_CENTCOMP" CC
                   ON C."U_GEI_CentC" = CC."Code"

WHERE
    V."DocDate" BETWEEN '[%DateFrom%]' AND '[%DateTo%]'
    AND CC."Name" IN ('CATALONIA HOTELS', 'ASOCIADO QUANTUM')

GROUP BY
    G."GroupCode",
    G."GroupName",
    CC."Name",
    V."DocDate",
    V."DocNum",
    C."CardCode",
    C."CardName",
    V."ShipToCode",
    V."Address2"

ORDER BY
    C."CardName",
    V."DocNum";