-- ============================================================
-- QUERY 2: RAWalbaranes
-- Replaces: RAWalbaranes sheet in Stock.xlsx
-- Loads into Power BI as table: RAWalbaranes
-- Schedule: Every Monday at 7:00 AM
--
-- Covers: All delivery notes (type V = sales, type T = transfer)
-- Columns produced (matching Excel exactly):
--   Fecha, Núm.Albarán, Fecha Albarán, Tipo, Código Pedido,
--   Fecha Pedido, Referencia Pedido, Agente, Cliente,
--   Nombre Fiscal, Nombre destinatario, Dirección destinatario,
--   C.Postal destinatario, Población destinatario,
--   Provincia destinatario, País destinatario, CIF destinatario,
--   Teléfono destinatario, Obs.destinatario, Portes, Valorado,
--   Enviado por, Sit.Impr., Sit.Exp., Sit.Conf., Depósito,
--   F.Pago, F.Entrega, F.Valor, Dto.1, Dto.2, Dto.3, Dto.PP,
--   Gtos.Fin., Ramo, Artículo, Descripción, Cantidad,
--   Precio, Dtos., Importe, P.Coste, Imp.Coste,
--   Proveedor, Familia
-- ============================================================

SELECT
    -- Snapshot date (week this data was pulled)
    DLN."DocDate"                                                   AS "Fecha",

    -- Delivery note header
    DLN."DocNum"                                                    AS "Núm.Albarán",
    DLN."DocDate"                                                   AS "Fecha Albarán",
    'V'                                                             AS "Tipo",

    -- Linked sales order
    COALESCE(TO_NVARCHAR(ORD."DocNum"), '')                        AS "Código Pedido",
    ORD."DocDate"                                                   AS "Fecha Pedido",
    COALESCE(DLN."NumAtCard", '')                                  AS "Referencia Pedido",

    -- Agent & client
    SLP."SlpCode"                                                   AS "Agente",
    CRD."CardCode"                                                  AS "Cliente",
    CRD."CardName"                                                  AS "Nombre Fiscal",

    -- Ship-to address
    COALESCE(DLN."ShipToCode", '')                                 AS "Nombre destinatario",
    COALESCE(ADR."Street", '')                                     AS "Dirección destinatario",
    COALESCE(ADR."ZipCode", '')                                    AS "C.Postal destinatario",
    COALESCE(ADR."City", '')                                       AS "Población destinatario",
    COALESCE(ADR."State", '')                                      AS "Provincia destinatario",
    COALESCE(CNT."Name", '')                                       AS "País destinatario",
    COALESCE(CRD."LicTradNum", '')                                 AS "CIF destinatario",
    COALESCE(CRD."Phone1", '')                                     AS "Teléfono destinatario",
    COALESCE(CRD."Notes", '')                                      AS "Obs.destinatario",

    -- Logistics
    CASE DLN."TrnspCode"
        WHEN 1 THEN 'Pagados'
        WHEN 2 THEN 'Debidos'
        ELSE ''
    END                                                             AS "Portes",
    ''                                                              AS "Valorado",
    COALESCE(TRP."TrnspName", '')                                  AS "Enviado por",

    -- Print / export / confirm status
    CASE DLN."Printed" WHEN 'Y' THEN 'Impreso' ELSE 'Pt.Imp.' END AS "Sit.Impr.",
    ''                                                              AS "Sit.Exp.",
    ''                                                              AS "Sit.Conf.",

    -- Warehouse
    DN1."WhsCode"                                                   AS "Depósito",

    -- Payment & delivery terms
    COALESCE(TO_NVARCHAR(DLN."GroupNum"), '')                      AS "F.Pago",
    DLN."DocDueDate"                                               AS "F.Entrega",
    DLN."TaxDate"                                                   AS "F.Valor",

    -- Discounts
    COALESCE(DLN."DiscPrcnt", 0)                                   AS "Dto.1",
    0                                                               AS "Dto.2",
    0                                                               AS "Dto.3",
    0                                                               AS "Dto.PP",
    0                                                               AS "Gtos.Fin.",

    -- Industry sector (Ramo) - from customer group
    COALESCE(CG."GroupName", '')                                   AS "Ramo",

    -- Line detail
    DN1."ItemCode"                                                  AS "Artículo",
    DN1."Dscription"                                               AS "Descripción",
    DN1."Quantity"                                                  AS "Cantidad",
    DN1."Price"                                                     AS "Precio",
    COALESCE(DN1."DiscPrcnt", 0)                                   AS "Dtos.",
    DN1."LineTotal"                                                 AS "Importe",
    DN1."StockPrice"                                               AS "P.Coste",
    DN1."StockPrice" * DN1."Quantity"                              AS "Imp.Coste",

    -- Supplier (preferred supplier from OITM.CardCode)
    COALESCE(SUPP."CardName", '')                                  AS "Proveedor",

    -- Product family
    COALESCE(ITB."ItmsGrpNam", '')                                 AS "Familia"

FROM        ODLN  DLN
JOIN        DLN1  DN1   ON DN1."DocEntry"    = DLN."DocEntry"
JOIN        OCRD  CRD   ON CRD."CardCode"    = DLN."CardCode"
JOIN        OSLP  SLP   ON SLP."SlpCode"     = DLN."SlpCode"
LEFT JOIN   ORDR  ORD   ON ORD."DocEntry"    = DLN."BaseEntry"
                        AND DLN."BaseType"   = 17
LEFT JOIN   CRD1  ADR   ON ADR."CardCode"    = CRD."CardCode"
                        AND ADR."AdresType"  = 'S'
                        AND ADR."Address"    = DLN."ShipToCode"
LEFT JOIN   OCRY  CNT   ON CNT."Code"        = ADR."Country"
LEFT JOIN   OSHP  TRP   ON TRP."TrnspCode"   = DLN."TrnspCode"
LEFT JOIN   OITM  ITM   ON ITM."ItemCode"    = DN1."ItemCode"
LEFT JOIN   OITB  ITB   ON ITB."ItmsGrpCod"  = ITM."ItmsGrpCod"
LEFT JOIN   OCRG  CG    ON CG."GroupCode"    = CRD."GroupCode"
LEFT JOIN   OCRD  SUPP  ON SUPP."CardCode"   = ITM."CardCode"

WHERE
    DLN."CANCELED" = 'N'                          -- exclude cancelled
    AND DLN."DocDate" >= '2024-01-01'             -- adjust start date as needed
    -- AND DLN."DocDate" <= CURRENT_DATE          -- up to today (always current)

ORDER BY
    DLN."DocDate"  DESC,
    DLN."DocNum"   DESC,
    DN1."LineNum"  ASC
;
