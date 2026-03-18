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