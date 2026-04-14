-- ============================================================
-- ESTADÍSTICAS DE VENTAS
-- ------------------------------------------------------------
-- Descripción : Estadísticas de ventas por factura y línea.
--               Incluye cliente, artículo, familia, marca,
--               agente, costes, margen y proveedor.
-- Parámetros  : [%FechaDesde%] Fecha inicio (opcional)
--               [%FechaHasta%] Fecha fin    (opcional)
-- Tablas      : OINV, INV1, OCRD, OCRG, OITM, OITB, OMRC,
--               OSLP, OSHP
-- ============================================================

-- Pedidos de compra + Abonos de compra (en negativo)
SELECT
    -- PROVEEDOR
    C."CardCode"                                        AS "Codigo",
    C."CardName"                                        AS "Nombre Proveedor",

    -- PEDIDO COMPRA
    O."DocNum"                                          AS "Pedido",
    COALESCE(SO."ShipToCode", '')                       AS "Destinatario",
    COALESCE(CAD."Name", '')                            AS "Cadena",
    COALESCE(CEN."Name", '')                            AS "Central Compras",
    O."DocDate"                                         AS "F.Pedido",
    L."WhsCode"                                         AS "Deposito",
    O."DocDueDate"                                      AS "F.Entrega",

    -- ARTÍCULO
    CAST(L."ItemCode" AS NVARCHAR)                      AS "Articulo",
    L."Dscription"                                      AS "Descripcion",
    L."Quantity"                                        AS "Cantidad",
    L."Price"                                           AS "Precio",
    L."LineTotal"                                       AS "Importe",

    -- ALBARÁN RECEPCIÓN
    COALESCE(RN."DocNum", NULL)                         AS "Albaran Recepcion",

    -- JERARQUÍA ARTÍCULO
    COALESCE(I."U_GEST_Fam1", '')                       AS "Grupo",
    COALESCE(I."U_GEST_Fam2", '')                       AS "Familia",
    COALESCE(I."U_GEST_Fam3", '')                       AS "Subfamilia"

FROM "OPOR" O
INNER JOIN "POR1" L   ON O."DocEntry" = L."DocEntry"
INNER JOIN "OCRD" C   ON O."CardCode" = C."CardCode"
LEFT JOIN  "OITM" I   ON L."ItemCode" = I."ItemCode"
LEFT JOIN  "PDN1" RL  ON RL."BaseEntry" = O."DocEntry"
                      AND RL."BaseType" = 22
                      AND RL."ItemCode" = L."ItemCode"
                      AND RL."LineNum"  = L."LineNum"
LEFT JOIN  "OPDN" RN  ON RL."DocEntry" = RN."DocEntry"
LEFT JOIN  "ORDR" SO  ON L."BaseEntry" = SO."DocEntry"
                      AND L."BaseType" = 17
LEFT JOIN  "OCRD" SC  ON SO."CardCode" = SC."CardCode"
LEFT JOIN  "@GEI_CADENA"   CAD ON SC."U_GEI_Cadena" = CAD."Code"
LEFT JOIN  "@GEI_CENTCOMP" CEN ON SC."U_GEI_CentC"  = CEN."Code"

WHERE
    O."DocDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND (
        LOCATE(',' || C."CardCode" || ',', ',' || '[%Proveedor%]' || ',') > 0
        OR '[%Proveedor%]' = ''
    )

UNION ALL

-- ABONOS DE COMPRA (en negativo)
SELECT
    C."CardCode",
    C."CardName",
    O."DocNum",
    COALESCE(SO."ShipToCode", ''),
    COALESCE(CAD."Name", ''),
    COALESCE(CEN."Name", ''),
    O."DocDate",
    L."WhsCode",
    O."DocDueDate",
    CAST(L."ItemCode" AS NVARCHAR),
    L."Dscription",
    -L."Quantity",
    L."Price",
    -L."LineTotal",
    NULL,
    COALESCE(I."U_GEST_Fam1", ''),
    COALESCE(I."U_GEST_Fam2", ''),
    COALESCE(I."U_GEST_Fam3", '')

FROM "ORPC" O
INNER JOIN "RPC1" L   ON O."DocEntry" = L."DocEntry"
INNER JOIN "OCRD" C   ON O."CardCode" = C."CardCode"
LEFT JOIN  "OITM" I   ON L."ItemCode" = I."ItemCode"
LEFT JOIN  "ORDR" SO  ON L."BaseEntry" = SO."DocEntry"
                      AND L."BaseType" = 17
LEFT JOIN  "OCRD" SC  ON SO."CardCode" = SC."CardCode"
LEFT JOIN  "@GEI_CADENA"   CAD ON SC."U_GEI_Cadena" = CAD."Code"
LEFT JOIN  "@GEI_CENTCOMP" CEN ON SC."U_GEI_CentC"  = CEN."Code"

WHERE
    O."DocDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND (
        LOCATE(',' || C."CardCode" || ',', ',' || '[%Proveedor%]' || ',') > 0
        OR '[%Proveedor%]' = ''
    )

ORDER BY
    "Codigo",
    "Pedido",
    "Articulo";