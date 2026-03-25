-- ============================================================
-- LISTADO PEDIDOS PROVEEDORES
-- ------------------------------------------------------------
-- Descripción : Pedidos de compra abiertos con sus líneas.
--               Incluye datos del proveedor, artículo,
--               cantidades pendientes, precios e importe.
-- Parámetros  : [%0] Código/s de proveedor (opcional, separados
--               por comas). Si se deja vacío muestra todos.
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
    O."DocStatus" = 'O'
    AND (
        LOCATE(',' || C."CardCode" || ',', ',' || '[%0]' || ',') > 0
        OR '[%0]' = ''
    )

ORDER BY
    C."CardCode",
    O."DocNum",
    L."LineNum";
