/* ============================================================
 IVA REPERCUTIDO – CSV OFICIAL
 ------------------------------------------------------------
 - Origen: Facturas de clientes (OINV / INV1)
 - Una fila por factura y tipo impositivo
 - Formato listo para exportar a CSV
 ============================================================ */

SELECT
 TO_VARCHAR(V."DocNum") AS "N.REGISTRO",
 TO_VARCHAR(V."DocDate", 'DD/MM/YYYY') AS "FECHA",

/* NIF / DNI (fallback estándar SAP B1) */
COALESCE(C."FederalTaxID", C."LicTradNum", '') AS "NIF/DNI",

 C."CardName" AS "NOMBRE",

/* BASE IMPONIBLE */
SUM(L."LineTotal") AS "BASE IVA",

/* TIPO IMPOSITIVO */
COALESCE(T."Rate", 0) AS "TIPO",

/* CUOTA IVA */
SUM(L."LineTotal" * COALESCE(T."Rate",0) / 100) AS "CUOTA",

/* TOTAL DOCUMENTO */
SUM(L."LineTotal")
+ SUM(L."LineTotal" * COALESCE(T."Rate",0) / 100)
AS "TOTAL DOCUM",

/* F/A → siempre Factura */
'F' AS "F/A",

/* N/E → Nacional / Extranjero (ES = E) */
CASE
WHEN C."Country" = 'ES' THEN 'E'
ELSE 'N'
END AS "N/E",

/* Tipo AUT (no estándar SAP) */
'' AS "Tipo AUT"

FROM "OINV" V
JOIN "INV1" L
ON V."DocEntry" = L."DocEntry"
JOIN "OCRD" C
ON V."CardCode" = C."CardCode"
LEFT JOIN "OVTG" T
ON L."VatGroup" = T."Code"

WHERE
 V."CANCELED" = 'N'
AND V."DocDate" BETWEEN DATE '2025-01-01' AND DATE '2025-01-31'

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
