-- ============================================================
-- LIBRO DE IGIC SOPORTADO
-- ------------------------------------------------------------
-- Descripción : Libro de IGIC soportado (compras). Una fila
--               por línea de factura de proveedor con tasa
--               IGIC. Incluye datos de pago y ref. de factura.
-- Parámetros  : [%FechaDesde%] Fecha inicio (YYYY-MM-DD)
--               [%FechaHasta%] Fecha fin    (YYYY-MM-DD)
-- Tablas      : OPCH, PCH1, OCRD, OVTG
-- ============================================================
SELECT
    C."DocEntry"                                              AS "N.REGISTRO",
    TO_VARCHAR(C."DocDate", 'DD/MM/YYYY')                    AS "FECHA",
    COALESCE(C."FederalTaxID", BP."LicTradNum", '')          AS "NIF/DNI",
    BP."CardName"                                            AS "NOMBRE",
    L."LineTotal"                                            AS "BASE IVA",
    T."Rate"                                                 AS "TIPO",
    (L."LineTotal" * T."Rate" / 100)                        AS "CUOTA",
    (L."LineTotal" + (L."LineTotal" * T."Rate" / 100))      AS "TOTAL DOCUM",
    CASE
        WHEN C."DocType" = 'I' THEN 'F'
        ELSE 'A'
    END                                                      AS "F/A",
    'N'                                                      AS "N/I",
    'N'                                                      AS "N/B",
    ''                                                       AS "Tipo AUT",
    COALESCE(C."NumAtCard", '')                              AS "S/factura",
    COALESCE(C."Comments", '')                               AS "Comentarios",
    ''                                                       AS "Factura Directa a",
    TO_VARCHAR(C."DocDueDate", 'DD/MM/YYYY')                 AS "Fecha Pago",
    C."PaidToDate"                                           AS "Importe Pago",
    COALESCE(C."CashAcct", '')                               AS "Medio Cuenta",
    L."VatGroup"                                             AS "Cod.Imp.",
    T."Name"                                                 AS "Descripción"
FROM "OPCH" C
INNER JOIN "PCH1" L  ON C."DocEntry" = L."DocEntry"
LEFT  JOIN "OCRD" BP ON C."CardCode" = BP."CardCode"
LEFT  JOIN "OVTG" T  ON L."VatGroup" = T."Code"
WHERE
    T."Name" LIKE '%IGIC%'
    AND C."DocDate" >= TO_DATE('[%FechaDesde%]', 'YYYY-MM-DD')
    AND C."DocDate" <= TO_DATE('[%FechaHasta%]', 'YYYY-MM-DD')
    AND C."CANCELED" = 'N'
ORDER BY
    C."DocDate",
    C."DocNum",
    L."LineNum";
