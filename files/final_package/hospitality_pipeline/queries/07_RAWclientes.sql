-- ============================================================
-- QUERY 07: RAWclientes (Client Master + New Client Flag)
-- Used by:  Hospitality pipeline
-- Replaces: 'Clients' sheet + 'Clientes nuevos Pro' logic
-- Loads into Power BI as table: RAWclientes
-- Schedule: Every Monday at 7:00 AM
--
-- The "NUEVO" flag in the Excel is based on whether the client
-- had their first invoice in 2026. This query calculates it
-- automatically from OINV.
--
-- Source tables:
--   OCRD  Customer master
--   OSLP  Sales agents
--   OCRG  Customer groups (Ramo)
--   OINV  Invoices (for first invoice date = new client detection)
--   CRD1  Customer addresses
--
-- Columns produced (matching both Excel sheets):
--   CODIGO, RAZON-SOCIAL, NOMBRE-COMERCIAL, TELEFONO-1,
--   EMAIL, AGENTE, DESCRIPCION-RAMO,
--   PRIMER_FACTURA, ES_NUEVO_2026, TOTAL_FACTURADO_2026
-- ============================================================

SELECT
    CRD."CardCode"                                                  AS "CODIGO",
    CRD."CardName"                                                  AS "RAZON-SOCIAL",
    COALESCE(CRD."CardFName", '')                                  AS "NOMBRE-COMERCIAL",
    COALESCE(CRD."Phone1", '')                                     AS "TELEFONO-1",
    COALESCE(CRD."E_Mail", '')                                     AS "EMAIL",
    SLP."SlpCode"                                                   AS "AGENTE",
    SLP."SlpName"                                                   AS "NOMBRE-AGENTE",
    COALESCE(CRG."GroupName", '')                                  AS "DESCRIPCION-RAMO",

    -- First invoice date (any year) — used to determine if new client
    (
        SELECT MIN(I2."DocDate")
        FROM   OINV I2
        WHERE  I2."CardCode" = CRD."CardCode"
        AND    I2."CANCELED" = 'N'
    )                                                               AS "PRIMER_FACTURA",

    -- New client flag: first ever invoice was in 2026
    CASE
        WHEN (
            SELECT MIN(I3."DocDate")
            FROM   OINV I3
            WHERE  I3."CardCode" = CRD."CardCode"
            AND    I3."CANCELED" = 'N'
        ) >= '2026-01-01' THEN 'NUEVO'
        ELSE ''
    END                                                             AS "ES_NUEVO_2026",

    -- Total invoiced in 2026 (for Clientes nuevos Pro ranking)
    COALESCE((
        SELECT SUM(I4."DocTotal")
        FROM   OINV I4
        WHERE  I4."CardCode" = CRD."CardCode"
        AND    I4."CANCELED" = 'N'
        AND    I4."DocDate"  >= '2026-01-01'
    ), 0)                                                           AS "TOTAL_FACTURADO_2026",

    -- Active / inactive
    CASE CRD."validFor" WHEN 'Y' THEN 'Activo' ELSE 'Inactivo' END AS "ESTADO",

    -- Additional contact
    COALESCE(CRD."Phone2", '')                                     AS "TELEFONO-2",
    ''                                                              AS "EMAIL-FACTURAS",    -- E_MailL no existe en OCRD
    COALESCE(CRD."CntctPrsn", '')                                  AS "PERSONA-CONTACTO",
    COALESCE(CRD."LicTradNum", '')                                 AS "CIF"

FROM        OCRD  CRD
JOIN        OSLP  SLP   ON SLP."SlpCode"   = CRD."SlpCode"
LEFT JOIN   OCRG  CRG   ON CRG."GroupCode" = CRD."GroupCode"

WHERE
    CRD."CardType" = 'C'                          -- customers only (not suppliers)
    AND CRD."validFor" = 'Y'                      -- active clients only
                                                  -- Remove to include inactive clients too

ORDER BY
    "TOTAL_FACTURADO_2026" DESC,
    CRD."CardName" ASC
;
