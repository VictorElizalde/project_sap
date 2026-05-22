-- ============================================================
-- QUERY 3: Raw PP (Pedidos Pendientes)
-- Replaces: Raw PP sheet in Stock.xlsx
-- Loads into Power BI as table: RAW_PedidosPendientes
-- Schedule: Every Monday at 7:00 AM
--
-- Covers: All open sales orders (status = Open)
-- Columns produced (matching Excel exactly):
--   Cliente, Nombre Cliente, Agente, Nombre Agente,
--   Pedido, F.Pedido, F.Entrega, Depósito, Observaciones,
--   Articulo, Descripcion, Cantidad, Precio, Importe,
--   Telefono, Telefono.1, Referencia Cliente,
--   E-Mail, E-Mail Facturas, Familia
-- ============================================================

SELECT
    -- Client info
    CRD."CardCode"                                                  AS "Cliente",
    CRD."CardName"                                                  AS "Nombre Cliente",

    -- Agent info
    SLP."SlpCode"                                                   AS "Agente",
    SLP."SlpName"                                                   AS "Nombre Agente",

    -- Order header
    ORD."DocNum"                                                    AS "Pedido",
    ORD."DocDate"                                                   AS "F.Pedido",
    ORD."DocDueDate"                                               AS "F.Entrega",
    RDR."WhsCode"                                                   AS "Depósito",
    COALESCE(ORD."Comments", '')                                   AS "Observaciones",

    -- Line detail
    RDR."ItemCode"                                                  AS "Articulo",
    RDR."Dscription"                                               AS "Descripcion",
    RDR."OpenQty"                                                   AS "Cantidad",       -- pending qty only
    RDR."Price"                                                     AS "Precio",
    RDR."OpenQty" * RDR."Price"                                    AS "Importe",        -- pending value

    -- Contact
    COALESCE(CRD."Phone1", '')                                     AS "Telefono",
    COALESCE(CRD."Phone2", '')                                     AS "Telefono.1",
    COALESCE(ORD."NumAtCard", '')                                  AS "Referencia Cliente",
    COALESCE(CRD."E_Mail", '')                                     AS "E-Mail",
    ''                                                              AS "E-Mail Facturas",   -- E_MailL no existe en OCRD

    -- Product family
    COALESCE(ITB."ItmsGrpNam", '')                                 AS "Familia"

FROM        ORDR  ORD
JOIN        RDR1  RDR   ON RDR."DocEntry"    = ORD."DocEntry"
JOIN        OCRD  CRD   ON CRD."CardCode"    = ORD."CardCode"
JOIN        OSLP  SLP   ON SLP."SlpCode"     = ORD."SlpCode"
LEFT JOIN   OITM  ITM   ON ITM."ItemCode"    = RDR."ItemCode"
LEFT JOIN   OITB  ITB   ON ITB."ItmsGrpCod"  = ITM."ItmsGrpCod"

WHERE
    ORD."DocStatus" = 'O'                         -- open orders only
    AND ORD."CANCELED" = 'N'                      -- not cancelled
    AND RDR."OpenQty" > 0                         -- lines with pending quantity

ORDER BY
    ORD."DocDate"   ASC,
    SLP."SlpName"   ASC,
    CRD."CardName"  ASC,
    RDR."LineNum"   ASC
;
