SELECT
  -- Pedido
  O."DocNum"                      AS "Código Pedido",
  O."DocDate"                     AS "Fecha Pedido",

  -- Albarán
  D."DocNum"                      AS "Núm.Albarán",
  D."DocDate"                     AS "Fecha Albarán",
  D."NumAtCard"                   AS "Expediente",

  -- Destinatario
  C."CardCode"                    AS "Código destinatario",
  C."CardName"                    AS "Nombre destinatario",

  A."Street"                      AS "Dirección destinatario",
  A."ZipCode"                     AS "C.Postal destinatario",
  A."City"                        AS "Población destinatario",
  A."County"                      AS "Provincia destinatario",
  A."Country"                     AS "País destinatario",

  C."LicTradNum"                  AS "CIF destinatario",
  C."Phone1"                      AS "Teléfono destinatario",

  D."Comments"                    AS "Obs.destinatario",

  -- Transporte
  D."TotalExpns"                  AS "Portes",
  D."DocTotal"                    AS "Albarán valorado",

  T."TrnspName"                   AS "Transportista",

  -- Línea
  L."LineNum" + 1                 AS "Línea comanda",
  L."ItemCode"                    AS "Código artículo",
  L."Dscription"                 AS "Descripción",
  L."Quantity"                   AS "Cantidad",
  I."SWeight1" * L."Quantity"    AS "Peso",

  -- Contacto
  C."E_Mail"                      AS "e-mail",

  -- Referencias
  O."NumAtCard"                   AS "Referencia Pedido",
  O."Comments"                    AS "Observaciones externas",
  D."Comments"                    AS "Observaciones almacén"

FROM "ODLN" D
JOIN "DLN1" L       ON D."DocEntry" = L."DocEntry"
LEFT JOIN "RDR1" RL ON L."BaseEntry" = RL."DocEntry"
                    AND L."BaseLine" = RL."LineNum"
                    AND L."BaseType" = 17
LEFT JOIN "ORDR" O  ON RL."DocEntry" = O."DocEntry"
JOIN "OCRD" C       ON D."CardCode" = C."CardCode"
LEFT JOIN "CRD1" A  ON C."CardCode" = A."CardCode"
                    AND A."AdresType" = 'S'
                    AND A."Address" = D."ShipToCode"
LEFT JOIN "OITM" I  ON L."ItemCode" = I."ItemCode"
LEFT JOIN "OSHP" T  ON D."TrnspCode" = T."TrnspCode"

-- For one or multiple albaranes: LOCATE(',' || CAST(D."DocNum" AS VARCHAR) || ',', ',' || '[%Albaran%]' || ',') > 0

WHERE
  C."CardCode" = '[%Cliente%]'
  AND (
    '[%Albaran%]' = ''
    OR LOCATE(',' || CAST(D."DocNum" AS VARCHAR) || ',', ',' || '[%Albaran%]' || ',') > 0
)

ORDER BY
  D."DocNum",
  L."LineNum";