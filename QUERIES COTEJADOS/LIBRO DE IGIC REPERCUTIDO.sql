/* =====================================================================================
 LIBRO DE IGIC REPERCUTIDO – DETALLE POR FACTURA
 -------------------------------------------------------------------------------------
 ✔ Estructura compatible con CSV solicitado
 ✔ Una fila por línea de factura
 ✔ IGIC repercutido (ventas)
 ✔ Base y cuota calculadas correctamente
 -------------------------------------------------------------------------------------
 CONSIDERACIONES:
 - Sustituye al query agregado por tasa
 - Si necesitas totales por IGIC, se agrupan en Excel
 - LicTradNum se usa como NIF/DNI (revisar localización)
 - Tipo AUT se deja fijo salvo UDF específico
 ===================================================================================== */

SELECT
 V."DocNum" AS "N.REGISTRO",
 TO_VARCHAR(V."DocDate", 'DD/MM/YYYY') AS "FECHA",
 C."LicTradNum" AS "NIF/DNI",
 C."CardName" AS "NOMBRE",

 /* Base imponible por línea */
 (L."LineTotal" * (1 - COALESCE(L."DiscPrcnt",0) / 100)) AS "BASE IVA",

 COALESCE(T."Rate", 0) AS "TIPO",

 /* Cuota IGIC */
 (L."LineTotal" * (1 - COALESCE(L."DiscPrcnt",0) / 100))
 * COALESCE(T."Rate",0) / 100 AS "CUOTA",

 V."DocTotal" AS "TOTAL DOCUM",

 'F' AS "F/A",
 V."DocNum" AS "N/E",
 'AUT' AS "Tipo AUT"

FROM "OINV" V
INNER JOIN "INV1" L ON V."DocEntry" = L."DocEntry"
INNER JOIN "OCRD" C ON V."CardCode" = C."CardCode"
LEFT JOIN "OVTG" T ON L."VatGroup" = T."Code"

WHERE
 T."Name" LIKE '%IGIC%'
AND V."DocDate" BETWEEN :P_FECHA_INICIO AND :P_FECHA_FIN
AND V."CANCELED" = 'N'

ORDER BY
 V."DocDate",
 V."DocNum";

/* =====================================================================================
 FIN QUERY
 ===================================================================================== */
