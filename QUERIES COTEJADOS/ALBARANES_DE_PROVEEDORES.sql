-- ============================================================
-- LISTADO ALBARANES PROVEEDORES
-- ------------------------------------------------------------
-- Descripción : Albaranes de compra con sus líneas en un rango
--               de fechas. Incluye pedido base, proveedor,
--               dirección de entrega, depósito y artículos.
-- Parámetros  : [%FechaDesde%] Fecha inicio (opcional)
--               [%FechaHasta%] Fecha fin    (opcional)
--               [%Proveedor%]  Código/s de proveedor, separados
--                              por comas (opcional)
-- Tablas      : OPDN, PDN1, OPOR, OCRD
-- ============================================================
SELECT
    -- ALBARÁN
    D."DocNum"                                   AS "Núm.Albarán",
    D."DocDate"                                  AS "Fecha Albarán",

    -- PEDIDO BASE
    O."DocNum"                                   AS "Número Pedido",
    O."DocDate"                                  AS "Fecha Pedido",

    -- PROVEEDOR
    D."CardCode"                                 AS "Proveedor",
    C."CardName"                                 AS "Nombre",

    -- CLIENTE ASOCIADO AL PEDIDO DE COMPRA (via pedido de venta vinculado)
    COALESCE(SC."CardName", '')                  AS "Cliente",

    -- NÚMERO DE PEDIDO DE CLIENTE VINCULADO
    COALESCE(CAST(SO."DocNum" AS VARCHAR), '')   AS "Núm.Ped.Cliente",

    -- ENTREGA (dirección real del albarán)
    SO."ShipToCode"                               AS "Entrega en",

    -- OBSERVACIONES INTERNAS DEL PEDIDO DE COMPRA
    COALESCE(O."Comments", '')                   AS "Observaciones",

    -- LÍNEA
    L."WhsCode"                                  AS "Depósito",
    L."ItemCode"                                 AS "Artículo",
    L."Dscription"                               AS "Descripción",
    L."Quantity"                                 AS "Cantidad",
    L."Price"                                    AS "Precio",
    L."LineTotal"                                AS "Importe"

FROM "OPDN" D
INNER JOIN "PDN1" L    ON D."DocEntry"   = L."DocEntry"
INNER JOIN "OCRD" C    ON D."CardCode"   = C."CardCode"
LEFT JOIN  "OPOR" O    ON L."BaseEntry"  = O."DocEntry"
                       AND L."BaseType"  = 22
-- Línea del pedido de compra para obtener el pedido de venta vinculado
LEFT JOIN  "POR1" PL   ON O."DocEntry"   = PL."DocEntry"
                       AND PL."BaseType" = 17
                       AND PL."ItemCode" = L."ItemCode"
-- Pedido de venta vinculado
LEFT JOIN  "ORDR" SO   ON PL."BaseEntry" = SO."DocEntry"
-- Cliente del pedido de venta
LEFT JOIN  "OCRD" SC   ON SO."CardCode"  = SC."CardCode"

WHERE
    D."DocDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND (
        LOCATE(',' || D."CardCode" || ',', ',' || '[%Proveedor%]' || ',') > 0
        OR '[%Proveedor%]' = ''
    )

ORDER BY
    D."DocNum",
    L."LineNum";