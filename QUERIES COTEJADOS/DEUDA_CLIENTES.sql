-- ============================================================
-- DEUDA CLIENTES
-- ------------------------------------------------------------
-- Descripción : Listado de facturas de clientes abiertas con
--               saldo pendiente. Muestra importe pendiente,
--               días de demora y datos fiscales del cliente.
-- Parámetros  : (ninguno) – muestra toda la deuda abierta
-- Tablas      : OINV, OCRD
-- ============================================================
-- DEUDA CLIENTES
-- Incluye: Facturas (OINV) + Anticipos (ODPI) + Abonos (ORIN en negativo)

SELECT
    I."CardCode"                                        AS "Cliente",
    C."CardName"                                        AS "Nombre",
    I."DocDueDate"                                      AS "Vto",
    I."DocNum"                                          AS "Documento",
    'FACTURA'                                           AS "Tipo Doc.",
    CASE
        WHEN I."DocStatus" = 'O' THEN 'PENDTE.'
        ELSE 'CERRADA'
    END                                                 AS "Situación",
    I."DocDate"                                         AS "Fecha",
    C."GroupNum"                                        AS "Tem.",
    COALESCE(SL."SlpName", '')                          AS "Agente",
    COALESCE(TG."PymntGroup", '')                       AS "Forma Pago",
    C."BankCode"                                        AS "Banco",
    0                                                   AS "Remesa",
    ''                                                  AS "T.Rem.",
    C."DebPayAcct"                                      AS "C.G.",
    (I."DocTotal" - I."PaidToDate")                     AS "Importe",
    (I."DocTotalFC" - I."PaidFC")                       AS "Importe Div.",
    I."DocCur"                                          AS "DIV",
    C."LicTradNum"                                      AS "NIF",
    COALESCE(CAD."Name", '')                            AS "Cadena",
    COALESCE(CEN."Name", '')                            AS "Central Compras",
    CASE
        WHEN I."DocStatus" = 'O'
         AND I."DocDueDate" < CURRENT_DATE
        THEN DAYS_BETWEEN(I."DocDueDate", CURRENT_DATE)
        ELSE 0
    END                                                 AS "Dias Demora"

FROM "OINV" I
JOIN  "OCRD" C    ON I."CardCode"       = C."CardCode"
LEFT JOIN "OSLP" SL   ON I."SlpCode"   = SL."SlpCode"
LEFT JOIN "OCTG" TG   ON I."GroupNum"  = TG."GroupNum"
LEFT JOIN "@GEI_CADENA"   CAD ON C."U_GEI_Cadena" = CAD."Code"
LEFT JOIN "@GEI_CENTCOMP" CEN ON C."U_GEI_CentC"  = CEN."Code"

WHERE
    I."DocStatus" = 'O'
    AND I."DocTotal" > I."PaidToDate"

UNION ALL

-- FACTURAS DE ANTICIPO PENDIENTES (ODPI)
SELECT
    I."CardCode",
    C."CardName",
    I."DocDueDate",
    I."DocNum",
    'ANTICIPO',
    CASE WHEN I."DocStatus" = 'O' THEN 'PENDTE.' ELSE 'CERRADA' END,
    I."DocDate",
    C."GroupNum",
    COALESCE(SL."SlpName", ''),
    COALESCE(TG."PymntGroup", ''),
    C."BankCode",
    0,
    '',
    C."DebPayAcct",
    (I."DocTotal" - I."PaidToDate"),
    (I."DocTotalFC" - I."PaidFC"),
    I."DocCur",
    C."LicTradNum",
    COALESCE(CAD."Name", ''),
    COALESCE(CEN."Name", ''),
    CASE
        WHEN I."DocStatus" = 'O'
         AND I."DocDueDate" < CURRENT_DATE
        THEN DAYS_BETWEEN(I."DocDueDate", CURRENT_DATE)
        ELSE 0
    END

FROM "ODPI" I
JOIN  "OCRD" C    ON I."CardCode"      = C."CardCode"
LEFT JOIN "OSLP" SL   ON I."SlpCode"  = SL."SlpCode"
LEFT JOIN "OCTG" TG   ON I."GroupNum" = TG."GroupNum"
LEFT JOIN "@GEI_CADENA"   CAD ON C."U_GEI_Cadena" = CAD."Code"
LEFT JOIN "@GEI_CENTCOMP" CEN ON C."U_GEI_CentC"  = CEN."Code"

WHERE
    I."DocStatus" = 'O'
    AND I."DocTotal" > I."PaidToDate"

UNION ALL

-- ABONOS / DEVOLUCIONES (ORIN - en negativo)
SELECT
    I."CardCode",
    C."CardName",
    I."DocDueDate",
    I."DocNum",
    'ABONO',
    CASE WHEN I."DocStatus" = 'O' THEN 'PENDTE.' ELSE 'CERRADA' END,
    I."DocDate",
    C."GroupNum",
    COALESCE(SL."SlpName", ''),
    COALESCE(TG."PymntGroup", ''),
    C."BankCode",
    0,
    '',
    C."DebPayAcct",
    -(I."DocTotal" - I."PaidToDate"),
    -(I."DocTotalFC" - I."PaidFC"),
    I."DocCur",
    C."LicTradNum",
    COALESCE(CAD."Name", ''),
    COALESCE(CEN."Name", ''),
    0

FROM "ORIN" I
JOIN  "OCRD" C    ON I."CardCode"      = C."CardCode"
LEFT JOIN "OSLP" SL   ON I."SlpCode"  = SL."SlpCode"
LEFT JOIN "OCTG" TG   ON I."GroupNum" = TG."GroupNum"
LEFT JOIN "@GEI_CADENA"   CAD ON C."U_GEI_Cadena" = CAD."Code"
LEFT JOIN "@GEI_CENTCOMP" CEN ON C."U_GEI_CentC"  = CEN."Code"

WHERE
    I."DocStatus" = 'O'
    AND I."DocTotal" > I."PaidToDate"

ORDER BY
    "Vto",
    "Nombre";
