-- ============================================================
-- QUERY 06: RAWinventario (Monthly Inventory Snapshot)
-- Used by:  Rentabilidad pipeline
-- Replaces: 'RAWinventario' sheet in 2026_Rentabilidad file
--           'RAW PARA ALBARANES' sheet (current date snapshot)
-- Loads into Power BI as table: RAWinventario
-- Schedule: Every Monday at 7:00 AM
--
-- NOTE: Unlike RAWstock (Stock.xlsx) which does weekly snapshots
-- over time via historical data, this query pulls the CURRENT
-- inventory state and tags it with the current month.
-- Power BI accumulates monthly snapshots over time.
--
-- Source tables:
--   OITW  Warehouse stock quantities
--   OITM  Item master (price, cost, brand, family)
--   OITB  Item groups
--   OPDN  Goods receipts (for age/entry date)
--   ORDR  Sales orders (for reserved qty)
--   OPOR  Purchase orders (pending to receive)
--
-- Columns produced (matching Excel exactly):
--   FECHA, MES, MARCA, NOMBRE MARCA, FAMILIA, NOMBRE FAMILIA,
--   SUBFAM, NOMBRE SUBFAMILIA, ARTICULO, DESCRIPCION,
--   DEPOSITO, CANTIDAD, PRECIO, IMPORTE, RESERVADO,
--   PT.RECIBIR, DISPON.FUTURO, ALBS.PTS., ALBS.CONF.,
--   PROV., NOMBRE, REF.PROVEEDOR, FAMILIA7
-- ============================================================

SELECT
    -- Snapshot date — always the last day of the current month
    LAST_DAY(CURRENT_DATE)                                          AS "FECHA",
    LOWER(MONTHNAME(CURRENT_DATE))                                  AS "MES",

    -- Brand
    COALESCE(ITM."U_MarcaCod", '')                                 AS "MARCA",
    COALESCE(ITM."U_Marca", '')                                    AS "NOMBRE MARCA",

    -- Family hierarchy
    ITB."ItmsGrpCod"                                               AS "FAMILIA",
    ITB."ItmsGrpNam"                                               AS "NOMBRE FAMILIA",
    COALESCE(ITM."U_SubfamCod", '')                                AS "SUBFAM",
    COALESCE(ITM."U_Subfamilia", '')                               AS "NOMBRE SUBFAMILIA",

    -- Article
    ITM."ItemCode"                                                  AS "ARTICULO",
    ITM."ItemName"                                                  AS "DESCRIPCION",

    -- Warehouse
    WH."WhsCode"                                                    AS "DEPOSITO",

    -- Stock quantities
    COALESCE(WH."OnHand", 0)                                       AS "CANTIDAD",
    COALESCE(ITM."AvgPrice", 0)                                    AS "PRECIO",
    COALESCE(ITM."AvgPrice", 0) * COALESCE(WH."OnHand", 0)       AS "IMPORTE",

    -- Reserved (open sales orders for this item)
    COALESCE((
        SELECT SUM(R1."OpenQty")
        FROM   ORDR SO
        JOIN   RDR1 R1 ON R1."DocEntry" = SO."DocEntry"
        WHERE  R1."ItemCode" = ITM."ItemCode"
        AND    SO."DocStatus" = 'O'
        AND    SO."CANCELED"  = 'N'
    ), 0)                                                           AS "RESERVADO",

    -- Pending to receive (open purchase orders)
    COALESCE((
        SELECT SUM(P1."OpenQty")
        FROM   OPOR PO
        JOIN   POR1 P1 ON P1."DocEntry" = PO."DocEntry"
        WHERE  P1."ItemCode" = ITM."ItemCode"
        AND    PO."DocStatus" = 'O'
        AND    PO."CANCELED"  = 'N'
    ), 0)                                                           AS "PT.RECIBIR",

    -- Available future = stock + pending to receive - reserved
    COALESCE(WH."OnHand", 0)
    + COALESCE((
        SELECT SUM(P1."OpenQty")
        FROM   OPOR PO
        JOIN   POR1 P1 ON P1."DocEntry" = PO."DocEntry"
        WHERE  P1."ItemCode" = ITM."ItemCode"
        AND    PO."DocStatus" = 'O'
    ), 0)
    - COALESCE((
        SELECT SUM(R1."OpenQty")
        FROM   ORDR SO
        JOIN   RDR1 R1 ON R1."DocEntry" = SO."DocEntry"
        WHERE  R1."ItemCode" = ITM."ItemCode"
        AND    SO."DocStatus" = 'O'
    ), 0)                                                           AS "DISPON.FUTURO",

    -- Pending delivery notes (open, not yet invoiced)
    COALESCE((
        SELECT SUM(D1."OpenQty")
        FROM   ODLN DL
        JOIN   DLN1 D1 ON D1."DocEntry" = DL."DocEntry"
        WHERE  D1."ItemCode" = ITM."ItemCode"
        AND    DL."DocStatus" = 'O'
        AND    DL."CANCELED"  = 'N'
    ), 0)                                                           AS "ALBS.PTS.",

    -- Confirmed delivery notes (closed, awaiting invoice)
    COALESCE((
        SELECT COUNT(DISTINCT DL."DocEntry")
        FROM   ODLN DL
        JOIN   DLN1 D1 ON D1."DocEntry" = DL."DocEntry"
        WHERE  D1."ItemCode" = ITM."ItemCode"
        AND    DL."DocStatus" = 'C'
        AND    DL."CANCELED"  = 'N'
        AND    DL."DocDate"   >= ADD_MONTHS(CURRENT_DATE, -1)
    ), 0)                                                           AS "ALBS.CONF.",

    -- Supplier info
    COALESCE((
        SELECT TOP 1 SC."SupplierCode"
        FROM   ITM1 SC
        WHERE  SC."ItemCode" = ITM."ItemCode"
        ORDER BY SC."LineNum"
    ), '')                                                          AS "PROV.",

    COALESCE((
        SELECT TOP 1 SUP."CardName"
        FROM   ITM1 SC
        JOIN   OCRD SUP ON SUP."CardCode" = SC."SupplierCode"
        WHERE  SC."ItemCode" = ITM."ItemCode"
        ORDER BY SC."LineNum"
    ), '')                                                          AS "NOMBRE",

    COALESCE((
        SELECT TOP 1 SC."SuppCatNum"
        FROM   ITM1 SC
        WHERE  SC."ItemCode" = ITM."ItemCode"
        ORDER BY SC."LineNum"
    ), '')                                                          AS "REF.PROVEEDOR",

    -- FAMILIA7 — simplified family grouping for rotation analysis
    CASE ITB."ItmsGrpNam"
        WHEN 'HOTEL TV'     THEN 'HOTEL TV'
        WHEN 'MONITORES'    THEN 'MONITORES'
        WHEN 'LED'          THEN 'LED'
        WHEN 'VIDEOWALL'    THEN 'MONITORES'
        WHEN 'TELEVISORES'  THEN 'TELEVISORES'
        WHEN 'SOPORTES'     THEN 'SOPORTES'
        ELSE 'RESTO'
    END                                                             AS "FAMILIA7"

FROM       OITM  ITM
JOIN       OITB  ITB  ON ITB."ItmsGrpCod" = ITM."ItmsGrpCod"
LEFT JOIN  OITW  WH   ON WH."ItemCode"    = ITM."ItemCode"
                      AND WH."WhsCode" NOT IN ('98','99')   -- exclude virtual warehouses

WHERE
    ITM."validFor"   = 'Y'                        -- active items only
    AND ITM."InvntItem" = 'Y'                     -- inventory-managed items only
    AND COALESCE(WH."OnHand", 0) > 0              -- only items with stock
                                                  -- Remove this line to include zero-stock items

ORDER BY
    ITB."ItmsGrpNam",
    ITM."U_Marca",
    ITM."ItemCode"
;
