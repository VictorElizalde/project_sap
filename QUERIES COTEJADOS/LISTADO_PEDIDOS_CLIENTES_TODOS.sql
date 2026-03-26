-- ============================================================
-- LISTADO PEDIDOS CLIENTES TODOS
-- ------------------------------------------------------------
-- Descripción : Todos los pedidos de venta (abiertos y cerrados)
--               con sus líneas. Incluye datos del cliente,
--               agente, artículo, cantidades y contacto.
-- Parámetros  : [%FechaDesde%] Fecha inicio (opcional)
--               [%FechaHasta%] Fecha fin    (opcional)
--               [%Cliente%]    Código/s de cliente, separados
--                              por comas (opcional)
-- Tablas      : ORDR, RDR1, OCRD, OSLP, OITM
-- ============================================================
SELECT
    -- CLIENTE
    C."CardCode"                                 AS "Cliente",
    C."CardName"                                 AS "Nombre Cliente",

    -- AGENTE
    O."SlpCode"                                  AS "Agente",
    COALESCE(S."SlpName", '')                    AS "Nombre Agente",

    -- PEDIDO
    O."DocNum"                                   AS "Pedido",
    O."DocDate"                                  AS "F.Pedido",
    O."DocDueDate"                               AS "F.Entrega",
    L."WhsCode"                                  AS "Depósito",
    O."PickRmrk"                                 AS "Observaciones Externas",

    -- ARTÍCULO
    L."ItemCode"                                 AS "Articulo",
    L."Dscription"                               AS "Descripcion",
    L."OpenQty"                                  AS "Ctd.Pendiente",
    L."Price"                                    AS "Precio",
    L."LineTotal"                                AS "Importe",

    -- CONTACTO
    COALESCE(C."Phone1", '')                     AS "Telefono",
    COALESCE(O."NumAtCard", '')                  AS "Telefono 2",
    L."PoTrgNum"                                 AS "Doc. Aprov.",
    C."CardCode"                                 AS "Referencia Cliente",
    ''                                           AS "E-Mail",
    ''                                           AS "E-Mail Facturas",

    -- FAMILIA
    '' AS "Familia"

FROM "ORDR" O
INNER JOIN "RDR1" L  ON O."DocEntry" = L."DocEntry"
INNER JOIN "OCRD" C  ON O."CardCode" = C."CardCode"
LEFT JOIN  "OSLP" S  ON O."SlpCode"  = S."SlpCode"
LEFT JOIN  "OITM" I  ON L."ItemCode" = I."ItemCode"

WHERE
    O."DocDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND (
        LOCATE(',' || C."CardCode" || ',', ',' || '[%Cliente%]' || ',') > 0
        OR '[%Cliente%]' = ''
    )

ORDER BY
    C."CardCode",
    O."DocNum",
    L."LineNum";