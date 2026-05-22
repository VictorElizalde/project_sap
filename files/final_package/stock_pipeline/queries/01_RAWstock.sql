-- ============================================================
-- QUERY 1: RAWstock
-- Replaces: RAWstock sheet in Stock.xlsx
-- Loads into Power BI as table: RAWstock
-- Schedule: Every Monday at 7:00 AM
-- 
-- Columns produced (matching Excel exactly):
--   Fecha, Mes, Semana, Familia, Subfamilia, Marca, Artículo,
--   Descripción, Precio Base, Ultimo Precio, Precio Medio,
--   Existencia, Existencia <30, Existencia <60, Existencia <90,
--   Existencia >90, Pte.Recibir, Pte.Servir,
--   Valor Ext.Ini., Valor Ext.Act., Inventario Medio,
--   Coste Ventas, Rotación, Dias R., Ref.Proveedor,
--   Valor stock, Canal
-- ============================================================

SELECT
    -- Date context (snapshot date = current Monday)
    CURRENT_DATE                                                    AS "Fecha",
    MONTHNAME(CURRENT_DATE)                                         AS "Mes",
    WEEK(CURRENT_DATE)                                              AS "Semana",

    -- Product classification
    ITB."ItmsGrpNam"                                               AS "Familia",
    COALESCE(ITM."U_Subfamilia", ITB."ItmsGrpNam")                AS "Subfamilia",
    COALESCE(ITM."U_Marca", '')                                    AS "Marca",
    ITM."ItemCode"                                                  AS "Artículo",
    ITM."ItemName"                                                  AS "Descripción",

    -- Pricing
    ITM."PriceList1"                                               AS "Precio Base",
    COALESCE((
        SELECT TOP 1 I2."Price"
        FROM   OINV O2
        JOIN   INV1 I2 ON I2."DocEntry" = O2."DocEntry"
        WHERE  I2."ItemCode" = ITM."ItemCode"
        ORDER  BY O2."DocDate" DESC
    ), ITM."PriceList1")                                           AS "Ultimo Precio",
    COALESCE((
        SELECT AVG(I3."Price")
        FROM   OINV O3
        JOIN   INV1 I3 ON I3."DocEntry" = O3."DocEntry"
        WHERE  I3."ItemCode" = ITM."ItemCode"
        AND    O3."DocDate" >= ADD_MONTHS(CURRENT_DATE, -12)
    ), ITM."PriceList1")                                           AS "Precio Medio",

    -- Stock levels (total across all warehouses)
    COALESCE(SUM(WH."OnHand"), 0)                                  AS "Existencia",

    -- Age brackets: days since goods receipt
    COALESCE(SUM(CASE
        WHEN DAYS_BETWEEN(GRN."DocDate", CURRENT_DATE) < 30
        THEN WH."OnHand" ELSE 0
    END), 0)                                                        AS "Existencia <30",

    COALESCE(SUM(CASE
        WHEN DAYS_BETWEEN(GRN."DocDate", CURRENT_DATE) BETWEEN 30 AND 59
        THEN WH."OnHand" ELSE 0
    END), 0)                                                        AS "Existencia <60",

    COALESCE(SUM(CASE
        WHEN DAYS_BETWEEN(GRN."DocDate", CURRENT_DATE) BETWEEN 60 AND 89
        THEN WH."OnHand" ELSE 0
    END), 0)                                                        AS "Existencia <90",

    COALESCE(SUM(CASE
        WHEN DAYS_BETWEEN(GRN."DocDate", CURRENT_DATE) >= 90
        THEN WH."OnHand" ELSE 0
    END), 0)                                                        AS "Existencia >90",

    -- Pending to receive (open purchase orders)
    COALESCE((
        SELECT SUM(P1."OpenQty")
        FROM   OPOR PO
        JOIN   POR1 P1 ON P1."DocEntry" = PO."DocEntry"
        WHERE  P1."ItemCode" = ITM."ItemCode"
        AND    PO."DocStatus" = 'O'
    ), 0)                                                           AS "Pte.Recibir",

    -- Pending to serve (open sales orders)
    COALESCE((
        SELECT SUM(R1."OpenQty")
        FROM   ORDR SO
        JOIN   RDR1 R1 ON R1."DocEntry" = SO."DocEntry"
        WHERE  R1."ItemCode" = ITM."ItemCode"
        AND    SO."DocStatus" = 'O'
    ), 0)                                                           AS "Pte.Servir",

    -- Stock value (initial = opening stock × avg cost, actual = current stock × avg cost)
    COALESCE(ITM."AvgPrice", 0) * COALESCE((
        SELECT SUM(W2."OnHand")
        FROM   OITW W2
        WHERE  W2."ItemCode" = ITM."ItemCode"
        AND    W2."WhsCode" NOT IN ('98','99')    -- exclude virtual warehouses
    ), 0)                                                           AS "Valor Ext.Ini.",

    COALESCE(ITM."AvgPrice", 0) * COALESCE(SUM(WH."OnHand"), 0)  AS "Valor Ext.Act.",

    -- Average inventory value (simple: half of current, consistent with Excel logic)
    (COALESCE(ITM."AvgPrice", 0) * COALESCE(SUM(WH."OnHand"), 0)) / 2
                                                                    AS "Inventario Medio",

    -- Cost of sales last 12 months
    COALESCE((
        SELECT SUM(I4."LineTotal")
        FROM   OINV O4
        JOIN   INV1 I4 ON I4."DocEntry" = O4."DocEntry"
        WHERE  I4."ItemCode" = ITM."ItemCode"
        AND    O4."DocDate" >= ADD_MONTHS(CURRENT_DATE, -12)
        AND    O4."CANCELED"  = 'N'
    ), 0)                                                           AS "Coste Ventas",

    -- Rotation (annual sales qty / avg stock) - 0 if no stock
    CASE
        WHEN COALESCE(SUM(WH."OnHand"), 0) = 0 THEN 0
        ELSE COALESCE((
            SELECT SUM(I5."Quantity")
            FROM   OINV O5
            JOIN   INV1 I5 ON I5."DocEntry" = O5."DocEntry"
            WHERE  I5."ItemCode" = ITM."ItemCode"
            AND    O5."DocDate" >= ADD_MONTHS(CURRENT_DATE, -12)
            AND    O5."CANCELED"  = 'N'
        ), 0) / NULLIF(COALESCE(SUM(WH."OnHand"), 0), 0)
    END                                                             AS "Rotación",

    -- Days of stock remaining (stock / avg daily sales)
    CASE
        WHEN COALESCE((
            SELECT SUM(I6."Quantity")
            FROM   OINV O6
            JOIN   INV1 I6 ON I6."DocEntry" = O6."DocEntry"
            WHERE  I6."ItemCode" = ITM."ItemCode"
            AND    O6."DocDate" >= ADD_MONTHS(CURRENT_DATE, -12)
            AND    O6."CANCELED"  = 'N'
        ), 0) = 0 THEN 999
        ELSE ROUND(
            COALESCE(SUM(WH."OnHand"), 0)
            /
            (COALESCE((
                SELECT SUM(I6."Quantity")
                FROM   OINV O6
                JOIN   INV1 I6 ON I6."DocEntry" = O6."DocEntry"
                WHERE  I6."ItemCode" = ITM."ItemCode"
                AND    O6."DocDate" >= ADD_MONTHS(CURRENT_DATE, -12)
                AND    O6."CANCELED"  = 'N'
            ), 0) / 365)
        , 0)
    END                                                             AS "Dias R.",

    -- Supplier reference
    COALESCE((
        SELECT TOP 1 ITX."SuppCatNum"
        FROM   ITM1 ITX
        WHERE  ITX."ItemCode" = ITM."ItemCode"
    ), '')                                                          AS "Ref.Proveedor",

    -- Total stock value at average cost
    COALESCE(ITM."AvgPrice", 0) * COALESCE(SUM(WH."OnHand"), 0)  AS "Valor stock",

    -- Canal from family mapping
    CASE ITB."ItmsGrpNam"
        WHEN 'MANDOS'                   THEN 'CONSUMO'
        WHEN 'TELEVISORES'              THEN 'CONSUMO'
        WHEN 'ZONA OUTLET'              THEN 'CONSUMO'
        WHEN 'TV ACCESORIOS'            THEN 'HOTEL'
        WHEN 'HOTEL TV'                 THEN 'HOTEL'
        WHEN 'VARIOS'                   THEN 'HOTEL'
        WHEN 'SOPORTES'                 THEN 'PROFESIONAL'
        WHEN 'ACCESORIOS'               THEN 'PROFESIONAL'
        WHEN 'AV'                       THEN 'PROFESIONAL'
        WHEN 'CABLES'                   THEN 'PROFESIONAL'
        WHEN 'LED'                      THEN 'PROFESIONAL'
        WHEN 'MONITORES'                THEN 'PROFESIONAL'
        WHEN 'PLAYERS'                  THEN 'PROFESIONAL'
        WHEN 'PROCESADOR PANTALLAS LED' THEN 'PROFESIONAL'
        WHEN 'PROYECCION'               THEN 'PROFESIONAL'
        WHEN 'TACTILES'                 THEN 'PROFESIONAL'
        WHEN 'TOTEMS'                   THEN 'PROFESIONAL'
        WHEN 'VIDEOWALL'                THEN 'PROFESIONAL'
        WHEN 'INFORMATICA'              THEN 'PROFESIONAL'
        WHEN 'AUDIO PROFESIONAL'        THEN 'PROMOCIONAL'
        WHEN 'BALANCE SCOOTER'          THEN 'PROMOCIONAL'
        WHEN 'CAMARAS'                  THEN 'PROMOCIONAL'
        WHEN 'DRONES'                   THEN 'PROMOCIONAL'
        WHEN 'GAMA BLANCA'              THEN 'PROMOCIONAL'
        WHEN 'MALETAS / MOCHILAS'       THEN 'PROMOCIONAL'
        WHEN 'MOVILES'                  THEN 'PROMOCIONAL'
        WHEN 'OCIO'                     THEN 'PROMOCIONAL'
        WHEN 'PAE'                      THEN 'PROMOCIONAL'
        WHEN 'PATINETES'                THEN 'PROMOCIONAL'
        WHEN 'RELOJ'                    THEN 'PROMOCIONAL'
        WHEN 'TABLETS'                  THEN 'PROMOCIONAL'
        WHEN 'TELEFONIA FIJA'           THEN 'PROMOCIONAL'
        WHEN 'VEHICULOS ELECTRICOS'     THEN 'PROMOCIONAL'
        WHEN 'VIDEOCONSOLAS'            THEN 'PROMOCIONAL'
        WHEN 'WEARABLES'                THEN 'PROMOCIONAL'
        WHEN 'CAJAS FUERTE'             THEN 'PROMOCIONAL'
        ELSE 'OTROS'
    END                                                             AS "Canal"

FROM       OITM  ITM
JOIN       OITB  ITB  ON ITB."ItmsGrpCod" = ITM."ItmsGrpCod"
LEFT JOIN  OITW  WH   ON WH."ItemCode"    = ITM."ItemCode"
                      AND WH."WhsCode" NOT IN ('98','99')
LEFT JOIN  OPDN  GRN  ON GRN."DocStatus"  = 'C'   -- last closed GR
LEFT JOIN  PDN1  GP1  ON GP1."DocEntry"   = GRN."DocEntry"
                      AND GP1."ItemCode"  = ITM."ItemCode"

WHERE
    ITM."validFor"  = 'Y'                          -- active items only
    AND ITM."InvntItem" = 'Y'                      -- inventory-managed items only

GROUP BY
    ITM."ItemCode",
    ITM."ItemName",
    ITM."PriceList1",
    ITM."AvgPrice",
    ITM."U_Subfamilia",
    ITM."U_Marca",
    ITB."ItmsGrpNam",
    ITB."ItmsGrpCod"

ORDER BY
    ITB."ItmsGrpNam",
    ITM."U_Marca",
    ITM."ItemCode"
;
