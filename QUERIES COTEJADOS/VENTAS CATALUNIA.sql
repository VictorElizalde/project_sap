/* =====================================================================================
 INFORME: VENTAS CATALUNYA – FORMATO CSV
 SISTEMA: SAP Business One sobre HANA
 -------------------------------------------------------------------------------------
 OBJETIVO:
 - Listado de ventas (facturas de clientes) filtradas por grupo de clientes = CATALUNYA
 - Una fila por factura
 - Importe neto (sin IVA)
 - Estructura compatible con CSV solicitado
 -------------------------------------------------------------------------------------
 CONSIDERACIONES IMPORTANTES:
 1) El filtro "CATALUNYA" se aplica sobre OCRG.GroupName (grupo de clientes).
 2) El importe neto se calcula como SUM(INV1.LineTotal).
 3) Dirección de envío se toma desde INV12 (AddrType = 'S').
    - Si no existe INV12 en tu versión → usar OCRD.Address / MailAddress.
 4) Campos no estándar SAP se dejan explícitamente en blanco.
 5) Query preparado para:
    ✔ Query Manager
    ✔ DataGrip
    ✔ Exportación directa a CSV
 ===================================================================================== */

SELECT
 /* ================= CLIENTE AGRUPADO ================= */
 G."GroupName" AS "CLI-AG",
 G."GroupName" AS "Nombre_Cliente_Agrupado",

 /* ================= FACTURA ================= */
 TO_VARCHAR(V."DocDate", 'DD/MM/YYYY') AS "Fec.Fra.",
 '' AS "Se", -- No estándar en SAP
 V."DocNum" AS "Factur",

 /* ================= CLIENTE ================= */
 C."CardCode" AS "CodCli",
 C."CardName" AS "Nombre_Cliente",

 /* ================= DIRECCIÓN ENVÍO ================= */
 COALESCE(A."Address", '') AS "CodD",
 COALESCE(A."Street", '') AS "Nombre_Dir_Envio",

 /* ================= IMPORTE ================= */
 SUM(L."LineTotal") AS "Imp.Neto",

 /* ================= RAMO ================= */
 G."GroupName" AS "Nombre_Ramo",

 /* ================= REPETICIÓN CSV ================= */
 C."CardCode" AS "CodCli_Rep"

FROM "OINV" V
INNER JOIN "INV1" L
 ON V."DocEntry" = L."DocEntry"

INNER JOIN "OCRD" C
 ON V."CardCode" = C."CardCode"

LEFT JOIN "OCRG" G
 ON C."GroupCode" = G."GroupCode"

LEFT JOIN "INV12" A
 ON V."DocEntry" = A."DocEntry"
 AND A."AddrType" = 'S'

WHERE
 V."CANCELED" = 'N'
AND V."DocDate" BETWEEN :FechaInicio AND :FechaFin
AND G."GroupName" = 'CATALUNYA'

GROUP BY
 G."GroupName",
 V."DocDate",
 V."DocNum",
 C."CardCode",
 C."CardName",
 A."Address",
 A."Street"

ORDER BY
 C."CardName",
 V."DocNum";

/* =====================================================================================
 NOTAS FINALES:
 - El importe es NETO (sin IVA).
 - Si necesitas IVA o total documento:
   ▸ IVA → usar INV1.VatSum
   ▸ Total → usar OINV.DocTotal
 - Si CATALUNYA proviene de UDF:
   ▸ Sustituir OCRG.GroupName por OCRD.U_xxx
 - Si no existe INV12:
   ▸ Usar OCRD.Address / OCRD.MailAddress
 ===================================================================================== */
