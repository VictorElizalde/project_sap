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
    -- TIPO DE DOCUMENTO
    'Factura'                                           AS "Tipo",

    -- CLIENTE
    C."CardCode"                                        AS "Codigo",
    C."CardName"                                        AS "Nombre Cliente",

    -- DOCUMENTO
    O."DocNum"                                          AS "Num.Documento",
    O."DocDate"                                         AS "Fecha",

    -- VENDEDOR
    COALESCE(SL."SlpName", '')                          AS "Vendedor",

    -- DEPÓSITO Y ARTÍCULO
    L."WhsCode"                                         AS "Deposito",
    L."ItemCode"                                        AS "Articulo",
    L."Dscription"                                      AS "Descripcion",
    L."Quantity"                                        AS "Cantidad",
    L."Price"                                           AS "Precio",
    L."LineTotal"                                       AS "Importe",

    -- COSTE, MARGEN Y % MARGEN
    L."LineTotal" - L."GrssProfit"                      AS "Coste",
    L."GrssProfit"                                      AS "Margen",
    CASE
        WHEN L."LineTotal" <> 0
        THEN ROUND(L."GrssProfit" / L."LineTotal" * 100, 2)
        ELSE 0
    END                                                 AS "% Margen",

    -- JERARQUÍA ARTÍCULO
    COALESCE(I."U_GEST_Fam1", '')                       AS "Grupo",
    COALESCE(I."U_GEST_Fam2", '')                       AS "Familia",
    COALESCE(I."U_GEST_Fam3", '')                       AS "Subfamilia"

FROM "OINV" O
INNER JOIN "INV1"  L  ON O."DocEntry" = L."DocEntry"
INNER JOIN "OCRD"  C  ON O."CardCode" = C."CardCode"
LEFT JOIN  "OITM"  I  ON L."ItemCode" = I."ItemCode"
LEFT JOIN  "OSLP"  SL ON O."SlpCode"  = SL."SlpCode"

WHERE
    O."DocDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND (
        LOCATE(',' || C."CardCode" || ',', ',' || '[%Cliente%]' || ',') > 0
        OR '[%Cliente%]' = ''
    )
    AND (
        COALESCE(SL."SlpName", '') = '[%Vendedor%]'
        OR '[%Vendedor%]' = ''
    )

UNION ALL

-- FACTURAS DE ANTICIPO (Down Payment)
SELECT
    'Anticipo',
    C."CardCode",
    C."CardName",
    O."DocNum",
    O."DocDate",
    COALESCE(SL."SlpName", ''),
    L."WhsCode",
    L."ItemCode",
    L."Dscription",
    L."Quantity",
    L."Price",
    L."LineTotal",
    L."LineTotal" - L."GrssProfit",
    L."GrssProfit",
    CASE
        WHEN L."LineTotal" <> 0
        THEN ROUND(L."GrssProfit" / L."LineTotal" * 100, 2)
        ELSE 0
    END,
    COALESCE(I."U_GEST_Fam1", ''),
    COALESCE(I."U_GEST_Fam2", ''),
    COALESCE(I."U_GEST_Fam3", '')

FROM "ODPI" O
INNER JOIN "DPI1"  L  ON O."DocEntry" = L."DocEntry"
INNER JOIN "OCRD"  C  ON O."CardCode" = C."CardCode"
LEFT JOIN  "OITM"  I  ON L."ItemCode" = I."ItemCode"
LEFT JOIN  "OSLP"  SL ON O."SlpCode"  = SL."SlpCode"

WHERE
    O."DocDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND (
        LOCATE(',' || C."CardCode" || ',', ',' || '[%Cliente%]' || ',') > 0
        OR '[%Cliente%]' = ''
    )
    AND (
        COALESCE(SL."SlpName", '') = '[%Vendedor%]'
        OR '[%Vendedor%]' = ''
    )

UNION ALL

-- ABONOS / DEVOLUCIONES (en negativo)
SELECT
    'Abono',
    C."CardCode",
    C."CardName",
    O."DocNum",
    O."DocDate",
    COALESCE(SL."SlpName", ''),
    L."WhsCode",
    L."ItemCode",
    L."Dscription",
    -L."Quantity",
    L."Price",
    -L."LineTotal",
    -(L."LineTotal" - L."GrssProfit"),
    -L."GrssProfit",
    CASE
        WHEN L."LineTotal" <> 0
        THEN ROUND(L."GrssProfit" / L."LineTotal" * 100, 2)
        ELSE 0
    END,
    COALESCE(I."U_GEST_Fam1", ''),
    COALESCE(I."U_GEST_Fam2", ''),
    COALESCE(I."U_GEST_Fam3", '')

FROM "ORIN" O
INNER JOIN "RIN1"  L  ON O."DocEntry" = L."DocEntry"
INNER JOIN "OCRD"  C  ON O."CardCode" = C."CardCode"
LEFT JOIN  "OITM"  I  ON L."ItemCode" = I."ItemCode"
LEFT JOIN  "OSLP"  SL ON O."SlpCode"  = SL."SlpCode"

WHERE
    O."DocDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND (
        LOCATE(',' || C."CardCode" || ',', ',' || '[%Cliente%]' || ',') > 0
        OR '[%Cliente%]' = ''
    )
    AND (
        COALESCE(SL."SlpName", '') = '[%Vendedor%]'
        OR '[%Vendedor%]' = ''
    )

ORDER BY
    "Fecha" DESC,
    "Codigo",
    "Num.Documento",
    "Articulo";