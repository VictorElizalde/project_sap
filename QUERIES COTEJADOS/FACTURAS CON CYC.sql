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
    TO_VARCHAR(V.DocDueDate, 'DD/MM/YYYY') AS "Vencimiento",
    TO_VARCHAR(V.DocDate, 'DD/MM/YYYY')    AS "Fecha Factura",
    C.CardName                             AS "Razón Fiscal",
    C.LicTradNum                           AS "NIF",
    V.DocTotal                             AS "Importe",
    V.DocNum                               AS "Numero Factura",
    V.CardCode                             AS "Cliente"
FROM OINV V
         JOIN OCRD C ON V.CardCode = C.CardCode
WHERE
    MONTH(V.DocDate) = :P_MES
  AND YEAR(V.DocDate) = :P_ANO
  AND V.CANCELED = 'N'
ORDER BY V.DocDate, V.DocNum;

/* =====================================================================================
   FIN QUERY
   ===================================================================================== */
