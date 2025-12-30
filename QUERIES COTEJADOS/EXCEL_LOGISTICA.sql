-- NO ERRORS
SELECT
 COALESCE(o."DocNum", d."DocNum")            AS "Código Pedido",
 TO_VARCHAR(o."DocDate", 'DD/MM/YYYY')      AS "Fecha Pedido",
 d."DocNum"                                 AS "Núm.Albarán",
 TO_VARCHAR(d."DocDate", 'DD/MM/YYYY')      AS "Fecha Albarán",

 d."CardCode"                               AS "Código destinatario",
 d."CardName"                               AS "Nombre destinatario",

 COALESCE(d."Address2", d."Address")        AS "Dirección destinatario",

 COALESCE(c."ZipCode",'')                   AS "C.Postal destinatario",
 COALESCE(c."City",'')                      AS "Población destinatario",
 COALESCE(c."State1",'')                    AS "Provincia destinatario",
 COALESCE(c."Country",'')                   AS "País destinatario",

 COALESCE(c."LicTradNum",'')                AS "CIF destinatario",
 COALESCE(c."Phone1",'')                    AS "Teléfono destinatario",

 CASE
   WHEN UPPER(COALESCE(l."ItemCode",'')) LIKE '%PORT%'
   THEN l."LineTotal"
   ELSE NULL
 END                                        AS "Portes",

 d."DocTotal"                               AS "Valor Asegurado",

 l."LineNum"                                AS "Línea",
 l."ItemCode"                               AS "Código artículo",
 l."Dscription"                             AS "Descripción",
 l."Quantity"                               AS "Cantidad",

 COALESCE(c."E_Mail",'')                    AS "Email",
 COALESCE(d."Comments",'')                  AS "Observaciones",

 d."BPLName"                                AS "Datos empresa"

FROM "ODLN" d
INNER JOIN "DLN1" l ON d."DocEntry" = l."DocEntry"
LEFT JOIN "ORDR" o  ON o."DocEntry" = d."BaseEntry"
LEFT JOIN "OCRD" c  ON d."CardCode" = c."CardCode"

WHERE
 ( '[%0]' = '' OR d."DocNum" = TO_INTEGER('[%0]') )
AND
 ( '[%1]' = '' OR d."CardCode" = '[%1]' )
AND
 (
   '[%2]' = ''
   OR d."DocDate" >= TO_DATE('[%2]', 'DD/MM/YYYY')
 )

ORDER BY d."DocNum", l."LineNum";
