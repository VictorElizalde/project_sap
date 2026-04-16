-- ============================================================
-- DEUDA CLIENTES
-- ------------------------------------------------------------
-- Descripción : Listado de facturas de clientes abiertas con
--               saldo pendiente. Muestra importe pendiente,
--               días de demora y datos fiscales del cliente.
-- Parámetros  : (ninguno) – muestra toda la deuda abierta
-- Tablas      : OINV, OCRD
-- ============================================================
SELECT
    I."CardCode"                                   AS "Cliente",
    C."CardName"                                   AS "Nombre",
    I."DocDueDate"                                 AS "Vto",
    I."DocNum"                                     AS "Documento",
    'TRANSF.'                                      AS "Tipo Doc.",
    CASE
        WHEN I."DocStatus" = 'O' THEN 'PENDTE.'
        ELSE 'CERRADA'
    END                                            AS "Situación",
    I."DocDate"                                    AS "Fecha",
    C."GroupNum"                                   AS "Tem.",
    I."SlpCode"                                    AS "Agente",
    C."BankCode"                                   AS "Banco",
    0                                              AS "Remesa",
    ''                                             AS "T.Rem.",
    C."DebPayAcct"                                 AS "C.G.",
    (I."DocTotal" - I."PaidToDate")                AS "Importe",
    (I."DocTotalFC" - I."PaidFC")                  AS "Importe Div.",
    I."DocCur"                                     AS "DIV",
    C."LicTradNum"                                 AS "NIF",
    ''                                             AS "Cl.Agrup.",
    CASE
        WHEN I."DocStatus" = 'O'
         AND I."DocDueDate" < CURRENT_DATE
        THEN DAYS_BETWEEN(I."DocDueDate", CURRENT_DATE)
        ELSE 0
    END                                            AS "Dias Demora"
FROM "OINV" I
JOIN "OCRD" C
  ON I."CardCode" = C."CardCode"
WHERE
    I."DocStatus" = 'O'
    AND I."DocTotal" > I."PaidToDate"
ORDER BY
    I."DocDueDate",
    C."CardName";
