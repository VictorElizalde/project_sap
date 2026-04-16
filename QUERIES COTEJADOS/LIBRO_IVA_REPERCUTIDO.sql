-- ============================================================
-- LIBRO IVA REPERCUTIDO
-- ------------------------------------------------------------
-- Descripción : Libro de IVA repercutido (ventas). Una fila
--               por factura de cliente y tipo impositivo.
--               Calcula base imponible, cuota y total agrupados.
-- Parámetros  : [%FechaDesde%] Fecha inicio (YYYY-MM-DD)
--               [%FechaHasta%] Fecha fin    (YYYY-MM-DD)
-- Tablas      : OINV, INV1, OCRD, OVTG
-- ============================================================
SELECT
    TO_VARCHAR(V."DocNum")                                           AS "N.REGISTRO",
    TO_VARCHAR(V."DocDate", 'DD/MM/YYYY')                           AS "FECHA",
    COALESCE(C."FederalTaxID", C."LicTradNum", '')                  AS "NIF/DNI",
    C."CardName"                                                     AS "NOMBRE",
    SUM(L."LineTotal")                                              AS "BASE IVA",
    COALESCE(T."Rate", 0)                                           AS "TIPO",
    SUM(L."LineTotal" * COALESCE(T."Rate", 0) / 100)               AS "CUOTA",
    SUM(L."LineTotal")
        + SUM(L."LineTotal" * COALESCE(T."Rate", 0) / 100)         AS "TOTAL DOCUM",
    'F'                                                              AS "F/A",
    CASE
        WHEN C."Country" = 'ES' THEN 'E'
        ELSE 'N'
    END                                                              AS "N/E",
    ''                                                               AS "Tipo AUT"
FROM "OINV" V
JOIN "INV1" L      ON V."DocEntry" = L."DocEntry"
JOIN "OCRD" C      ON V."CardCode" = C."CardCode"
LEFT JOIN "OVTG" T ON L."VatGroup" = T."Code"
WHERE
    V."CANCELED" = 'N'
    AND V."DocDate" >= TO_DATE('[%FechaDesde%]', 'YYYY-MM-DD')
    AND V."DocDate" <= TO_DATE('[%FechaHasta%]', 'YYYY-MM-DD')
GROUP BY
    V."DocNum",
    V."DocDate",
    COALESCE(C."FederalTaxID", C."LicTradNum", ''),
    C."CardName",
    T."Rate",
    C."Country"
ORDER BY
    V."DocDate",
    V."DocNum";
