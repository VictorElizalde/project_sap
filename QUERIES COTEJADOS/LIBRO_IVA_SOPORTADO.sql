-- ============================================================
-- LIBRO IVA SOPORTADO
-- ------------------------------------------------------------
-- Descripción : Libro de IVA soportado (compras). Una fila
--               por factura de proveedor y tipo impositivo.
--               Incluye datos de pago desde OVPM/VPM2.
-- Parámetros  : [%FechaDesde%] Fecha inicio (YYYY-MM-DD)
--               [%FechaHasta%] Fecha fin    (YYYY-MM-DD)
-- Tablas      : OPCH, PCH1, OVTG, OCRD, VPM2, OVPM
-- ============================================================
SELECT
    C."DocEntry"                                  AS "N.REGISTRO",
    TO_VARCHAR(C."DocDate", 'DD/MM/YYYY')         AS "FECHA",
    BP."LicTradNum"                               AS "NIF/DNI",
    BP."CardName"                                 AS "NOMBRE",
    SUM(L."LineTotal")                            AS "BASE IVA",
    T."Rate"                                      AS "TIPO",
    SUM(L."LineTotal" * T."Rate" / 100)           AS "CUOTA",
    C."DocTotal"                                  AS "TOTAL DOCUM",
    'F'                                           AS "F/A",
    ''                                            AS "N/I",
    ''                                            AS "N/B",
    ''                                            AS "Tipo AUT",
    C."NumAtCard"                                 AS "S/factura",
    C."Comments"                                  AS "Comentarios",
    BP."CardName"                                 AS "Factura Directa a",
    TO_VARCHAR(P."DocDate", 'DD/MM/YYYY')         AS "Fecha Pago",
    P."DocTotal"                                  AS "Importe Pago",
    P."CashAcct"                                  AS "Medio Cuenta",
    T."Code"                                      AS "Cod.Imp.",
    T."Name"                                      AS "Descripción"
FROM "OPCH" C
INNER JOIN "PCH1" L  ON C."DocEntry" = L."DocEntry"
LEFT  JOIN "OVTG" T  ON L."VatGroup" = T."Code"
LEFT  JOIN "OCRD" BP ON C."CardCode" = BP."CardCode"
LEFT  JOIN "VPM2" P2 ON P2."DocEntry" = C."DocEntry" AND P2."InvType" = 18
LEFT  JOIN "OVPM" P  ON P."DocEntry" = P2."DocNum"
WHERE
    C."DocDate" >= TO_DATE('[%FechaDesde%]', 'YYYY-MM-DD')
    AND C."DocDate" <= TO_DATE('[%FechaHasta%]', 'YYYY-MM-DD')
    AND T."Rate" IS NOT NULL
GROUP BY
    C."DocEntry",
    C."DocDate",
    BP."LicTradNum",
    BP."CardName",
    T."Rate",
    C."DocTotal",
    C."NumAtCard",
    C."Comments",
    P."DocDate",
    P."DocTotal",
    P."CashAcct",
    T."Code",
    T."Name"
ORDER BY
    C."DocDate",
    C."DocEntry",
    T."Rate";
