-- ============================================================
-- LIBRO DE IGIC REPERCUTIDO
-- ------------------------------------------------------------
-- Descripción : Libro de IGIC repercutido (ventas). Una fila
--               por línea de factura de cliente con tasa IGIC.
--               Calcula base imponible, cuota y total.
-- Parámetros  : [%FechaDesde%] Fecha inicio (YYYY-MM-DD)
--               [%FechaHasta%] Fecha fin    (YYYY-MM-DD)
-- Tablas      : OINV, INV1, OCRD, OVTG
-- ============================================================
SELECT
    V."DocNum"                                                      AS "N.REGISTRO",
    TO_VARCHAR(V."DocDate", 'DD/MM/YYYY')                          AS "FECHA",
    C."LicTradNum"                                                  AS "NIF/DNI",
    C."CardName"                                                    AS "NOMBRE",
    (L."LineTotal" * (1 - COALESCE(L."DiscPrcnt", 0) / 100))      AS "BASE IVA",
    COALESCE(T."Rate", 0)                                           AS "TIPO",
    (L."LineTotal" * (1 - COALESCE(L."DiscPrcnt", 0) / 100))
        * COALESCE(T."Rate", 0) / 100                              AS "CUOTA",
    V."DocTotal"                                                    AS "TOTAL DOCUM",
    'F'                                                             AS "F/A",
    V."DocNum"                                                      AS "N/E",
    'AUT'                                                           AS "Tipo AUT"
FROM "OINV" V
INNER JOIN "INV1" L  ON V."DocEntry" = L."DocEntry"
INNER JOIN "OCRD" C  ON V."CardCode" = C."CardCode"
LEFT  JOIN "OVTG" T  ON L."VatGroup" = T."Code"
WHERE
    T."Name" LIKE '%IGIC%'
    AND V."DocDate" >= TO_DATE('[%FechaDesde%]', 'YYYY-MM-DD')
    AND V."DocDate" <= TO_DATE('[%FechaHasta%]', 'YYYY-MM-DD')
    AND V."CANCELED" = 'N'
ORDER BY
    V."DocDate",
    V."DocNum";
