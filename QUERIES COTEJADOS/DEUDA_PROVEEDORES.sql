-- ============================================================
-- DEUDA PROVEEDORES
-- ------------------------------------------------------------
-- Descripción : Listado de facturas de proveedores abiertas
--               con saldo pendiente. Incluye importe en moneda
--               extranjera, forma de pago y fecha de corte.
-- Parámetros  : [%FechaHasta%] Fecha de corte (YYYY-MM-DD).
--               Si se deja vacío usa la fecha actual.
-- Tablas      : OPCH, OCRD
-- ============================================================
SELECT
    P."CardCode"                                   AS "Proveedor",
    P."CardName"                                   AS "Nombre",
    TO_VARCHAR(F."DocDueDate", 'DD/MM/YYYY')       AS "Vto",
    F."DocNum"                                     AS "Documento",
    CASE F."ObjType"
        WHEN '18' THEN 'Factura Proveedor'
        WHEN '19' THEN 'Nota Crédito Proveedor'
        ELSE 'Documento'
    END                                            AS "Tipo Doc.",
    TO_VARCHAR(F."DocDate", 'DD/MM/YYYY')          AS "Fecha",
    COALESCE(F."NumAtCard", '')                    AS "S/Factura",
    F."DocStatus"                                  AS "Est.",
    F."DocEntry"                                   AS "Id.",
    COALESCE(F."PeyMethod", '')                    AS "T.P.",
    COALESCE(P."BankCode", '')                     AS "Banco",
    ''                                             AS "C.I.G.",
    (F."DocTotal" - F."PaidToDate")                AS "Importe",
    CASE
        WHEN F."DocTotalFC" <> 0
        THEN (F."DocTotalFC" - F."PaidFC")
        ELSE 0
    END                                            AS "Importe Div.",
    F."DocCur"                                     AS "DIV"
FROM "OPCH" F
JOIN "OCRD" P
  ON F."CardCode" = P."CardCode"
WHERE
    F."DocStatus" = 'O'
    AND F."DocTotal" > F."PaidToDate"
    AND F."DocDate" <= CASE WHEN '[%FechaHasta%]' = '' THEN CURRENT_DATE ELSE TO_DATE('[%FechaHasta%]', 'YYYY-MM-DD') END
ORDER BY
    P."CardName",
    F."DocDueDate";
