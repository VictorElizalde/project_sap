-- ============================================================
-- LISTADO PEDIDOS CLIENTES
-- ------------------------------------------------------------
-- Descripción : Pedidos de venta abiertos con sus líneas.
--               Incluye datos del cliente, agente, artículo,
--               cantidades pendientes, precios y contacto
--               (teléfono, e-mail y e-mail de facturas).
-- Parámetros  : [%0] Código/s de cliente (opcional, separados
--               por comas). Si se deja vacío muestra todos.
-- Tablas      : ORDR, RDR1, OCRD, OSLP, OITM, CRD1
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
    COALESCE(W."OnHand", 0)                      AS "Stock",
    COALESCE(O."ShipToCode", '')                 AS "Dir.Entrega",

    -- ARTÍCULO
    L."ItemCode"                                 AS "Articulo",
    L."Dscription"                               AS "Descripcion",
    L."OpenQty"                                  AS "Ctd.Pendiente",
    L."Price"                                    AS "Precio",
    L."LineTotal"                                AS "Importe",

    -- CONTACTO
    COALESCE(C."Phone1", '')                     AS "Telefono",
    ''                                           AS "Telefono 2",
    L."PoTrgNum"                                 AS "Doc. Aprov.",
    C."CardCode"                                 AS "Referencia Cliente",
    COALESCE(O."NumAtCard", '')                  AS "Nº Ref. Cliente",
    ''                                           AS "E-Mail Facturas",

    -- FAMILIA
    '' AS "Familia"

FROM "ORDR" O
INNER JOIN "RDR1" L  ON O."DocEntry" = L."DocEntry"
INNER JOIN "OCRD" C  ON O."CardCode" = C."CardCode"
LEFT JOIN  "OSLP" S  ON O."SlpCode"  = S."SlpCode"
LEFT JOIN  "OITM" I  ON L."ItemCode" = I."ItemCode"
LEFT JOIN  "OITW" W  ON W."ItemCode" = L."ItemCode"
                    AND W."WhsCode"  = L."WhsCode"

WHERE
    O."DocStatus" = 'O'
    AND L."OpenQty" > 0
    AND (
        LOCATE(',' || C."CardCode" || ',', ',' || '[%0]' || ',') > 0
        OR '[%0]' = ''
    )

ORDER BY
    C."CardCode",
    O."DocNum",
    L."LineNum";