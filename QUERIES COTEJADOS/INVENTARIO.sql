/* =====================================================================
 QUERY: INVENTARIO (Stock por fecha)
 SISTEMA: SAP Business One sobre HANA

 PARÁMETROS:
 :P_FECHA_CONSULTA --> Fecha de corte del inventario

 NOTAS GENERALES:
 - El stock histórico se calcula SIEMPRE desde OINM.
 - OnHand / OnOrder / IsCommited son valores actuales (limitación SAP).
 - MARCA / SUBFAM / SERIE se asumen como UDFs en OITM.
 ===================================================================== */

SELECT
/* ============================
 CLASIFICACIÓN ARTÍCULO
 ============================ */
 I."U_MARCA"      AS "MARCA",
 M."Name"         AS "NOMBRE MARCA",

 I."ItmsGrpCod"   AS "FAMILIA",
 G."ItmsGrpNam"   AS "NOMBRE FAMILIA",

 I."U_SUBFAM"     AS "SUBFAM",
 SF."Name"        AS "NOMBRE SUBFAMILIA",

 I."U_SERIE"      AS "SERIE",
 SE."Name"        AS "NOMBRE SERIE",

/* ============================
 ARTÍCULO
 ============================ */
 I."ItemCode"     AS "ARTICULO",
 I."ItemName"     AS "DESCRIPCION",

/* ============================
 DEPÓSITO / STOCK
 ============================ */
 W."WhsCode"      AS "DEPOSITO",

 SUM(IT."InQty" - IT."OutQty") AS "CANTIDAD",

/* ============================
 VALORES ECONÓMICOS
 ============================ */
 I."AvgPrice" AS "PRECIO",

 SUM(IT."InQty" - IT."OutQty") * I."AvgPrice" AS "IMPORTE",

/* ============================
 DISPONIBILIDAD (ACTUAL)
 ============================ */
 I."IsCommited" AS "RESERVADO",
 I."OnOrder"    AS "PT.RECIBIR",
 I."OnHand" - I."IsCommited" + I."OnOrder" AS "DISPON.FUTURO",

/* ============================
 ALBARANES (NO ESTÁNDAR)
 ============================ */
 0 AS "ALBS.PTS.",
 0 AS "ALBS.CONF.",

/* ============================
 PROVEEDOR
 ============================ */
 I."CardCode"     AS "PROV.",
 BP."CardName"    AS "NOMBRE",
 I."SuppCatNum"  AS "REF.PROVEEDOR"

FROM "OINM" IT
INNER JOIN "OITM" I
 ON IT."ItemCode" = I."ItemCode"

INNER JOIN "OWHS" W
 ON IT."WhsCode" = W."WhsCode"

LEFT JOIN "OITB" G
 ON I."ItmsGrpCod" = G."ItmsGrpCod"

/* ======= UDFs / tablas auxiliares (AJUSTAR A TU SISTEMA) ======= */
LEFT JOIN "@MARCAS"  M  ON I."U_MARCA"  = M."Code"
LEFT JOIN "@SUBFAM"  SF ON I."U_SUBFAM" = SF."Code"
LEFT JOIN "@SERIES"  SE ON I."U_SERIE"  = SE."Code"

LEFT JOIN "OCRD" BP
 ON I."CardCode" = BP."CardCode"

WHERE
 IT."DocDate" <= :P_FECHA_CONSULTA

GROUP BY
 I."U_MARCA", M."Name",
 I."ItmsGrpCod", G."ItmsGrpNam",
 I."U_SUBFAM", SF."Name",
 I."U_SERIE", SE."Name",
 I."ItemCode", I."ItemName",
 W."WhsCode",
 I."AvgPrice",
 I."OnHand", I."IsCommited", I."OnOrder",
 I."CardCode", BP."CardName",
 I."SuppCatNum"

ORDER BY
 I."ItemCode",
 W."WhsCode";

/* =====================================================================
 CONSIDERACIONES FINALES IMPORTANTES
 - Stock a fecha: correcto vía OINM
 - Reservado / A recibir: solo estado actual SAP
 - ALBS.* se dejan en 0 por no ser estándar
 ===================================================================== */
