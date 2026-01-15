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
    /* CLI-AG */
    G."GroupCode"                                AS "CLI-AG",

    /* Nombre Cliente Agrupado */
    G."GroupName"                                AS "Nombre_Cliente_Agrupado",

    /* Fecha Factura */
    TO_VARCHAR(V."DocDate", 'DD/MM/YYYY')        AS "Fec.Fra.",

    /* Se (no estándar) */
    ''                                           AS "Se",

    /* Número de factura */
    V."DocNum"                                   AS "Factur",

    /* Código cliente */
    C."CardCode"                                 AS "CodCli",

    /* Nombre cliente */
    C."CardName"                                 AS "Nombre_Cliente",

    /* Código dirección envío */
    COALESCE(V."ShipToCode", '')                 AS "CodD",

    /* Dirección de envío (texto completo) */
    COALESCE(V."Address2", '')                   AS "Nombre_Dir_Envio",

    /* Importe neto */
    SUM(L."LineTotal")                           AS "Imp.Neto",

    /* Nombre ramo */
    G."GroupName"                                AS "Nombre_Ramo",

    /* CodCli repetido */
    C."CardCode"                                 AS "CodCli"

FROM "OINV" V
         JOIN "INV1" L
              ON V."DocEntry" = L."DocEntry"

         JOIN "OCRD" C
              ON V."CardCode" = C."CardCode"

         LEFT JOIN "OCRG" G
                   ON C."GroupCode" = G."GroupCode"

WHERE
    V."DocDate" BETWEEN DATE '2025-02-01' AND DATE '2026-01-01'
  AND G."GroupName" = 'CATALONIA'

GROUP BY
    G."GroupCode",
    G."GroupName",
    V."DocDate",
    V."DocNum",
    C."CardCode",
    C."CardName",
    V."ShipToCode",
    V."Address2"

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
