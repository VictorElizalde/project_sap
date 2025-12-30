/* =====================================================================
 LISTADO DE ALBARANES CLIENTES (por día) – SAP B1 HANA
 ---------------------------------------------------------------------
 QUERY LIMPIO / VALIDADO CONTRA DICCIONARIO ESTÁNDAR
 - Se evitan campos NO existentes en ODLN
 - Dirección y datos fiscales desde OCRD
 - Mantiene estructura y comentarios para CSV
 ===================================================================== */

SELECT
/* ================== DOCUMENTO ================== */
 D."DocNum" AS "Núm.Albarán",
 TO_VARCHAR(D."DocDate",'DD/MM/YYYY') AS "Fecha Albarán",
'ALBARÁN' AS "Tipo",

/* ================== PEDIDO BASE ================== */
COALESCE(O."DocNum", '') AS "Código Pedido",
 TO_VARCHAR(O."DocDate",'DD/MM/YYYY') AS "Fecha Pedido",
COALESCE(O."NumAtCard", '') AS "Referencia Pedido",

/* ================== COMERCIAL / CLIENTE ================== */
 D."SlpCode" AS "Agente",
 D."CardCode" AS "Cliente",
 C."CardName" AS "Nombre Fiscal",
 D."CardName" AS "Nombre destinatario",

/* ================== DIRECCIÓN (CLIENTE) ================== */
COALESCE(C."Address",'') AS "Dirección destinatario",
COALESCE(C."ZipCode",'') AS "C.Postal destinatario",
COALESCE(C."City",'') AS "Población destinatario",
COALESCE(C."State1",'') AS "Provincia destinatario",
COALESCE(C."Country",'') AS "País destinatario",

/* ================== DATOS FISCALES ================== */
COALESCE(C."LicTradNum",'') AS "CIF destinatario",
COALESCE(C."Phone1",'') AS "Teléfono destinatario",

/* ================== OBSERVACIONES ================== */
COALESCE(D."Comments",'') AS "Obs.destinatario",

/* ================== LOGÍSTICA ================== */
CASE
WHEN UPPER(L."ItemCode") LIKE '%PORTE%' THEN L."LineTotal"
ELSE 0
END AS "Portes",

 D."DocTotal" AS "Valorado",
'' AS "Enviado por",
'' AS "Sit.Impr.",
'' AS "Sit.Exp.",
'' AS "Sit.Conf.",

/* ================== FECHAS ================== */
 L."WhsCode" AS "Depósito",
 C."GroupNum" AS "F.Pago",
 TO_VARCHAR(D."DocDueDate",'DD/MM/YYYY') AS "F.Entrega",
 TO_VARCHAR(D."TaxDate",'DD/MM/YYYY') AS "F.Valor",

/* ================== DESCUENTOS ================== */
 L."DiscPrcnt" AS "Dto.1",
0 AS "Dto.2",
0 AS "Dto.3",
0 AS "Dto.PP",
0 AS "Gtos.Fin.",

/* ================== ARTÍCULOS ================== */
'' AS "Ramo",
 L."ItemCode" AS "Artículo",
 L."Dscription" AS "Descripción",
 L."Quantity" AS "Cantidad",
 L."Price" AS "Precio",
 L."DiscPrcnt" AS "Dtos.",
 L."LineTotal" AS "Importe",

/* ================== COSTES ================== */
 L."GrossBuyPrice" AS "P.Coste",
 (L."GrossBuyPrice" * L."Quantity") AS "Imp.Coste",

/* ================== PROVEEDOR / FAMILIA ================== */
'' AS "Proveedor",
 I."ItmsGrpCod" AS "Familia"

FROM "ODLN" D
INNER JOIN "DLN1" L ON D."DocEntry" = L."DocEntry"
LEFT JOIN "ORDR" O ON O."DocEntry" = L."BaseEntry"
AND L."BaseType" = 17
LEFT JOIN "OCRD" C ON D."CardCode" = C."CardCode"
LEFT JOIN "OITM" I ON L."ItemCode" = I."ItemCode"
LEFT JOIN "OWHS" W ON L."WhsCode" = W."WhsCode"

WHERE D."DocDate" = :FechaConsulta

ORDER BY D."DocNum", L."LineNum";

/* =====================================================================
 NOTAS FINALES:
 - Evita campos inexistentes en ODLN (ZipCode, Phone, FederalTaxID, etc.)
 - Dirección y fiscalidad desde OCRD (estándar)
 - Listo para Query Manager / DataGrip / CSV
 ===================================================================== */
