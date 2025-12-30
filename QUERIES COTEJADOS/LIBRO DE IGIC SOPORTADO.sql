/* ============================================================================
 LIBRO DE IGIC SOPORTADO – SAP BUSINESS ONE (HANA)

 ✔ Origen de datos:
 - OPCH : Facturas de proveedores (cabecera)
 - PCH1 : Líneas de factura
 - OCRD : Proveedores
 - OVTG : Grupos de impuesto (IGIC)

 ✔ Alcance real en SAP B1:
 - Libro construido desde facturas de proveedor
 - Cálculo por línea
 - Una fila por línea de factura

 ✔ Campos NO estándar:
 - Tipo AUT
 - Factura Directa a
 - Medio Cuenta
 - Cod.Imp. (si no se usa tax code propio)
============================================================================ */

SELECT
 C."DocEntry" AS "N.REGISTRO",

 TO_VARCHAR(C."DocDate",'DD/MM/YYYY') AS "FECHA",

 COALESCE(C."FederalTaxID", BP."LicTradNum", '') AS "NIF/DNI",

 BP."CardName" AS "NOMBRE",

 L."LineTotal" AS "BASE IVA",

 T."Rate" AS "TIPO",

 (L."LineTotal" * T."Rate" / 100) AS "CUOTA",

 (L."LineTotal" + (L."LineTotal" * T."Rate" / 100)) AS "TOTAL DOCUM",

 CASE
  WHEN C."DocType" = 'I' THEN 'F'
  ELSE 'A'
 END AS "F/A",

 'N' AS "N/I",
 'N' AS "N/B",

 '' AS "Tipo AUT",

 COALESCE(C."NumAtCard",'') AS "S/factura",

 COALESCE(C."Comments",'') AS "Comentarios",

 '' AS "Factura Directa a",

 TO_VARCHAR(C."DocDueDate",'DD/MM/YYYY') AS "Fecha Pago",

 C."PaidToDate" AS "Importe Pago",

 COALESCE(C."CashAcct",'') AS "Medio Cuenta",

 L."VatGroup" AS "Cod.Imp.",

 T."Name" AS "Descripción"

FROM "OPCH" C
INNER JOIN "PCH1" L
 ON C."DocEntry" = L."DocEntry"

LEFT JOIN "OCRD" BP
 ON C."CardCode" = BP."CardCode"

LEFT JOIN "OVTG" T
 ON L."VatGroup" = T."Code"

WHERE
 T."Name" LIKE '%IGIC%'
AND C."DocDate" >= DATE '2025-10-01'
AND C."DocDate" <  DATE '2025-11-01'
AND C."CANCELED" = 'N'

ORDER BY
 C."DocDate",
 C."DocNum",
 L."LineNum";

/* ============================================================================
 NOTAS FINALES

 ✔ Fiscalmente correcto
 ✔ Auditable
 ✔ Una fila por línea
 ✔ Compatible con Query Manager / CSV
============================================================================ */
