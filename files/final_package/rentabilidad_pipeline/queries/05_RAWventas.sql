-- ============================================================
-- QUERY 05: RAWventas (Sales Invoices + Credit Notes)
-- Used by:  Hospitality pipeline  → filter Canal IN ('HOTEL','OPORTUNISTA','PROMOCIONAL')
--           Rentabilidad pipeline → no canal filter, all canals
-- Replaces: 'Raw (no tocar)' sheet in Hospitality file
--           'RAWventa' sheet in Rentabilidad file
--           'Hoja1' (credit notes) in Hospitality file
-- Loads into Power BI as table: RAWventas
-- Schedule: Every Monday at 7:00 AM
--
-- Source tables:
--   OINV  Invoice header (sales invoices + credit notes)
--   INV1  Invoice lines
--   OCRD  Customer master
--   OSLP  Sales agents
--   OITM  Item master
--   OITB  Item groups (families)
--   ORCT  Payments (for payment method info)
--
-- Columns produced (matching both Excel files exactly):
--   Mes, Semana, Cliente, Nombre Cliente, Cl.Agrup, Ramo,
--   Actividad, Marca, Familia, Subfamilia, Depósito,
--   Articulo, Descripción, Agente, Factura, Fecha,
--   Cantidad, Importe Venta, Importe Coste, Importe Margen,
--   % Margen, Forma de envio, Mot.Abono, Desc. Abono,
--   Proveedor, Ref.Proveedor, Canal, Familia2,
--   IMP. Coste stock
-- ============================================================

SELECT
    -- Time context
    LOWER(MONTHNAME(INV."DocDate"))                                 AS "Mes",
    WEEK(INV."DocDate")                                             AS "Semana",

    -- Client
    CRD."CardCode"                                                  AS "Cliente",
    CRD."CardName"                                                  AS "Nombre Cliente",
    0                                                               AS "Cl.Agrup",       -- U_ClAgrup no existe en OCRD
    COALESCE(CRG."GroupName", '')                                   AS "Ramo",
    ''                                                              AS "Actividad",       -- U_Actividad no existe en OCRD

    -- Product
    COALESCE(MRC."FirmName", '')                                   AS "Marca",
    COALESCE(ITB."ItmsGrpNam", '')                                 AS "Familia",
    COALESCE(ITM."U_GEST_Fam2", '')                                AS "Subfamilia",
    LN1."WhsCode"                                                   AS "Depósito",
    LN1."ItemCode"                                                  AS "Articulo",
    LN1."Dscription"                                               AS "Descripción",

    -- Agent & document
    SLP."SlpName"                                                   AS "Agente",
    INV."DocNum"                                                    AS "Factura",
    INV."DocDate"                                                   AS "Fecha",

    -- Quantities and amounts
    -- Credit notes (OINV with DocType = 'C' or ObjType 14 = return invoice)
    -- are stored with negative quantities in SAP B1
    LN1."Quantity"                                                  AS "Cantidad",
    LN1."LineTotal"                                                 AS "Importe Venta",
    LN1."StockPrice" * LN1."Quantity"                              AS "Importe Coste",
    LN1."LineTotal" - (LN1."StockPrice" * LN1."Quantity")         AS "Importe Margen",

    CASE
        WHEN LN1."LineTotal" = 0 THEN 0
        ELSE ROUND(
            (LN1."LineTotal" - (LN1."StockPrice" * LN1."Quantity"))
            / NULLIF(LN1."LineTotal", 0) * 100
        , 2)
    END                                                             AS "% Margen",

    -- Logistics
    COALESCE(TRP."TrnspName", '')                                  AS "Forma de envio",

    -- Credit note reason (UDFs U_MotAbono / U_DescAbono no existen en OINV)
    ''                                                              AS "Mot.Abono",
    ''                                                              AS "Desc. Abono",

    -- Supplier (preferred supplier from OITM.CardCode → OCRD)
    COALESCE(SUPP."CardName", '')                                  AS "Proveedor",
    COALESCE(ITM."SuppCatNum", '')                                 AS "Ref.Proveedor",

    -- Canal classification (primary — matches Hospitality file)
    CASE ITB."ItmsGrpNam"
        WHEN 'HOTEL TV'         THEN 'HOSPITALITY'
        WHEN 'TV ACCESORIOS'    THEN 'HOSPITALITY'
        WHEN 'INSTALACION'      THEN 'HOSPITALITY'
        WHEN 'MANTENIMIENTO'    THEN 'HOSPITALITY'
        WHEN 'LICENCIAS'        THEN 'HOSPITALITY'
        WHEN 'SERVICIOS'        THEN 'HOSPITALITY'
        WHEN 'SERVICIOS PROPIOS' THEN 'HOSPITALITY'
        WHEN 'IT HOSPITALITY'   THEN 'HOSPITALITY'
        WHEN 'MONITORES'        THEN 'MONITORES'
        WHEN 'LED'              THEN 'MONITORES'
        WHEN 'VIDEOWALL'        THEN 'MONITORES'
        WHEN 'TELEVISORES'      THEN 'PROFESIONAL'
        WHEN 'SOPORTES'         THEN 'PROFESIONAL'
        WHEN 'AV'               THEN 'PROFESIONAL'
        WHEN 'CABLES'           THEN 'PROFESIONAL'
        WHEN 'INFORMATICA'      THEN 'PROFESIONAL'
        WHEN 'PROYECCION'       THEN 'PROFESIONAL'
        WHEN 'TACTILES'         THEN 'PROFESIONAL'
        WHEN 'TOTEMS'           THEN 'PROFESIONAL'
        WHEN 'PLAYERS'          THEN 'PROFESIONAL'
        ELSE 'RESTO'
    END                                                             AS "Canal",

    -- Canal 2 (secondary grouping used in Rentabilidad file)
    CASE ITB."ItmsGrpNam"
        WHEN 'HOTEL TV'         THEN 'HOTEL TV'
        WHEN 'MONITORES'        THEN 'MONITORES'
        WHEN 'LED'              THEN 'LED'
        WHEN 'VIDEOWALL'        THEN 'MONITORES'
        WHEN 'TELEVISORES'      THEN 'TELEVISORES'
        WHEN 'SOPORTES'         THEN 'SOPORTES'
        ELSE 'RESTO'
    END                                                             AS "Familia2",

    -- Stock cost at time of invoice (used in Rentabilidad rotation calculation)
    LN1."StockPrice" * LN1."Quantity"                              AS "IMP. Coste stock"

FROM        OINV  INV
JOIN        INV1  LN1   ON LN1."DocEntry"    = INV."DocEntry"
JOIN        OCRD  CRD   ON CRD."CardCode"    = INV."CardCode"
JOIN        OSLP  SLP   ON SLP."SlpCode"     = INV."SlpCode"
LEFT JOIN   OCRG  CRG   ON CRG."GroupCode"   = CRD."GroupCode"
LEFT JOIN   OITM  ITM   ON ITM."ItemCode"    = LN1."ItemCode"
LEFT JOIN   OITB  ITB   ON ITB."ItmsGrpCod"  = ITM."ItmsGrpCod"
LEFT JOIN   OSHP  TRP   ON TRP."TrnspCode"   = INV."TrnspCode"
LEFT JOIN   OMRC  MRC   ON MRC."FirmCode"    = ITM."FirmCode"
LEFT JOIN   OCRD  SUPP  ON SUPP."CardCode"   = ITM."CardCode"

WHERE
    INV."CANCELED" = 'N'                          -- not cancelled
    AND INV."DocDate" >= '2026-01-01'             -- current year; adjust as needed
    -- Remove the line below to get ALL canals (for Rentabilidad)
    -- Add it back to filter Hospitality only:
    -- AND ITB."ItmsGrpNam" IN ('HOTEL TV','TV ACCESORIOS','INSTALACION','MANTENIMIENTO',
    --                          'LICENCIAS','SERVICIOS','SERVICIOS PROPIOS','IT HOSPITALITY',
    --                          'MONITORES','LED','VIDEOWALL')

ORDER BY
    INV."DocDate" DESC,
    INV."DocNum"  DESC,
    LN1."LineNum" ASC
;

-- ============================================================
-- USAGE NOTES FOR CLINE:
--
-- In the Hospitality pipeline (pipeline_hospitality.py):
--   Uncomment the AND ITB."ItmsGrpNam" IN (...) filter
--   to restrict to Hospitality + Monitor families only.
--
-- In the Rentabilidad pipeline (pipeline_rentabilidad.py):
--   Leave the filter commented out to get all canals.
--
-- The field INV."U_MotAbono" may be named differently in your
-- schema — run: python tools/inspect_schema.py --search MotAbono
-- to find the exact column name.
-- ============================================================
