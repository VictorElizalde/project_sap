/* =====================================================================================
   INFORME C&C – DETALLE POR FACTURA (CSV EXACTO)
   -------------------------------------------------------------------------------------
   ✔ Una fila por factura
   ✔ Compatible con CSV solicitado
   ✔ Filtro por mes y año
   ✔ Datos fiscales desde OCRD
   -------------------------------------------------------------------------------------
   NOTAS IMPORTANTES:
   - Este query sustituye al informe agregado original
   - Si necesitas totales por mes, deben hacerse en Excel / Power BI
   - LicTradNum = NIF (puede variar por localización)
   ===================================================================================== */
SELECT
    TO_VARCHAR(V."DocDueDate", 'DD/MM/YYYY') AS "Vencimiento",
    TO_VARCHAR(V."DocDate", 'DD/MM/YYYY')    AS "Fecha Factura",
    C."CardName"                             AS "Razón Fiscal",
    C."LicTradNum"                           AS "NIF",
    V."DocTotal"                             AS "Importe",
    V."DocNum"                               AS "Numero Factura",
    V."CardCode"                             AS "Cliente"
FROM "OINV" V
         JOIN "OCRD" C
              ON V."CardCode" = C."CardCode"
WHERE
    V."DocDate" BETWEEN DATE '2025-01-01' AND DATE '2026-01-01'
  AND V."DocStatus" <> 'C'
ORDER BY
    V."DocDate",
    V."DocNum";

ORDER BY
 V."DocDate",
 V."DocNum";

/* =====================================================================================
 PARÁMETROS SAP B1:
 [%0] = Mes (1–12)
 [%1] = Año (ej. 2025)
 ===================================================================================== */
