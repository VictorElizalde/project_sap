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
  A."Address"                    AS "Nombre destinatario",

  A."Street"                      AS "Dirección destinatario",
  A."ZipCode"                     AS "C.Postal destinatario",
  A."City"                        AS "Población destinatario",
  A."County"                      AS "Provincia destinatario",
  A."Country"                     AS "País destinatario",

  A."LicTradNum"                  AS "CIF destinatario",
  A."U_Phone1"                      AS "Teléfono destinatario",

  D."PickRmrk"                    AS "Obs.destinatario",

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
  COALESCE(A."U_GEI_Mail", C."E_Mail")  AS "e-mail",

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

WHERE
  D."DocStatus" = 'O'
  AND (
    C."CardCode" = '[%0]'
    OR LOCATE(',' || CAST(D."DocNum" AS VARCHAR) || ',', ',' || '[%1]' || ',') > 0
    OR LOCATE(',' || CAST(D."DocNum" AS VARCHAR) || ',', ',' || '[%2]' || ',') > 0
    OR LOCATE(',' || CAST(D."DocNum" AS VARCHAR) || ',', ',' || '[%3]' || ',') > 0
    OR LOCATE(',' || CAST(D."DocNum" AS VARCHAR) || ',', ',' || '[%4]' || ',') > 0
  )

ORDER BY
  D."DocNum",
  L."LineNum";

-- =============================================================================
-- NOTAS:
-- - Parámetro [%0] = Código de cliente (obligatorio)
-- - Parámetro [%1] = Albarán 1 (ej: 100) - opcional
-- - Parámetro [%2] = Albarán 2 (ej: 101) - opcional
-- - Parámetro [%3] = Albarán 3 (ej: 102) - opcional
-- - Parámetro [%4] = Albarán 4 (ej: 103) - opcional
-- - Puede usar hasta 4 albaranes diferentes a la vez (límite de caracteres SAP B1)
-- - Si no especifica albaranes, muestra TODOS los del cliente
-- - Solo muestra albaranes con estado activo (DocStatus = 'O')
-- - Compatible con Query Manager / CSV / Excel
-- =============================================================================