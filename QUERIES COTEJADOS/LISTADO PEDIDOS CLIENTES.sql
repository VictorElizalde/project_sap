-- Ventas: Pedidos de clientes - Estado abierto al día de hoy
-- Parámetro [%0]: Código cliente (opcional, dejar vacío para todos)

SELECT
  C."CardCode" AS "Cliente",
  C."CardName" AS "Nombre Cliente",
  O."SlpCode" AS "Agente",
  COALESCE(S."SlpName", '') AS "Nombre Agente",
  O."DocNum" AS "Pedido",
  O."DocDate" AS "F.Pedido",
  O."DocDueDate" AS "F.Entrega",
--   COALESCE(O."WhsCode", '') AS "Depósito",
--   COALESCE(O."Comments", '') AS "Observaciones",
  L."ItemCode" AS "Articulo",
  L."Dscription" AS "Descripcion",
  L."Quantity" AS "Cantidad",
  L."Price" AS "Precio",
  L."LineTotal" AS "Importe",
  COALESCE(C."Phone1", '') AS "Telefono",
  COALESCE(C."Phone2", '') AS "Telefono2",
  C."CardCode" AS "Referencia Cliente",
  COALESCE(C."E_Mail", '') AS "E-Mail",
  COALESCE(C."E_Mail", '') AS "E-Mail Facturas",
  COALESCE(CAST(I."ItmsGrpCod" AS VARCHAR), '') AS "Familia"
FROM ORDR O
INNER JOIN RDR1 L ON O."DocEntry" = L."DocEntry"
INNER JOIN OCRD C ON O."CardCode" = C."CardCode"
LEFT JOIN OSLP S ON O."SlpCode" = S."SlpCode"
LEFT JOIN OITM I ON L."ItemCode" = I."ItemCode"
WHERE
  O."DocStatus" = 'O'
  AND (
    LOCATE(',' || C."CardCode" || ',', ',' || '[%0]' || ',') > 0
    OR '[%0]' = ''
  )