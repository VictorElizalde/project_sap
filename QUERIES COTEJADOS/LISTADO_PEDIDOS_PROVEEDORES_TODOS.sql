-- ============================================================
-- LISTADO PEDIDOS PROVEEDORES TODOS
-- ------------------------------------------------------------
-- Descripción : Todos los pedidos de compra (abiertos y cerrados)
--               con sus líneas. Incluye datos del proveedor,
--               artículo, cantidades, precios e importe.
-- Parámetros  : [%FechaDesde%]  Fecha inicio (opcional)
--               [%FechaHasta%]  Fecha fin    (opcional)
--               [%Proveedor%]   Código/s de proveedor, separados
--                               por comas (opcional)
-- Tablas      : OPOR, POR1, OCRD, OITM, OITB
-- ============================================================
SELECT
    -- PROVEEDOR
    C."CardCode"                                 AS "Codigo",
    C."CardName"                                 AS "Nombre Proveedor",

    -- PEDIDO
    O."DocNum"                                   AS "Pedido",
    L."WhsCode"                                  AS "Deposito",
    O."DocDate"                                  AS "F.Pedido",

    -- ARTÍCULO
    L."ItemCode"                                 AS "Articulo",
    L."Dscription"                               AS "Descripcion",
    L."OpenQty"                                  AS "Cantidad",
    L."Price"                                    AS "Precio",
    L."LineTotal"                                AS "Importe",

    -- FAMILIA
    COALESCE(G."ItmsGrpNam", '')                 AS "Familia"

FROM "OPOR" O
INNER JOIN "POR1" L  ON O."DocEntry" = L."DocEntry"
INNER JOIN "OCRD" C  ON O."CardCode" = C."CardCode"
LEFT JOIN  "OITM" I  ON L."ItemCode" = I."ItemCode"
LEFT JOIN  "OITB" G  ON I."ItmsGrpCod" = G."ItmsGrpCod"

WHERE
    O."DocDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND (
        LOCATE(',' || C."CardCode" || ',', ',' || '[%Proveedor%]' || ',') > 0
        OR '[%Proveedor%]' = ''
    )

ORDER BY
    C."CardCode",
    O."DocNum",
    L."LineNum";