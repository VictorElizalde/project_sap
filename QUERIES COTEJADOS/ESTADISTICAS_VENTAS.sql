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
SELECT
    C."CardCode"                                AS "Cliente",
    C."CardName"                                AS "Nombre Cliente",
    COALESCE(V."Address2", V."Address")         AS "DIRECCION ENTREGA DE CLIENTE",

    C."GroupCode"                               AS "Cl.Agrup",
    CG."GroupName"                              AS "Ramo",
    C."IndustryC"                               AS "Actividad",

    M."FirmName"                                AS "Marca",
    G."ItmsGrpNam"                              AS "Familia",

    L."WhsCode"                                 AS "Depósito",
    L."ItemCode"                                AS "Articulo",
    L."Dscription"                              AS "Descripción",

    S."SlpName"                                 AS "Agente",
    V."DocNum"                                  AS "Factura",
    TO_VARCHAR(V."DocDate",'DD/MM/YYYY')        AS "Fecha",

    L."Quantity"                                AS "Cantidad",
    L."LineTotal"                               AS "Importe Venta",

    COALESCE(L."StockValue",0)                  AS "Importe Coste",
    (L."LineTotal" - COALESCE(L."StockValue",0)) AS "Importe Margen",

    CASE
        WHEN L."LineTotal" <> 0
            THEN ROUND(
                (L."LineTotal" - COALESCE(L."StockValue",0))
                    / L."LineTotal" * 100, 2)
        ELSE 0
    END                                         AS "% Margen",

    SH."TrnspName"                              AS "Forma de envio",

    ''                                          AS "Mot.Abono",
    ''                                          AS "Desc. Abono",

    P."CardName"                                AS "Proveedor",
    I."SuppCatNum"                              AS "Ref.Proveedor"

FROM "OINV" V
JOIN "INV1" L   ON V."DocEntry" = L."DocEntry"
JOIN "OCRD" C   ON V."CardCode" = C."CardCode"
LEFT JOIN "OCRG" CG ON C."GroupCode" = CG."GroupCode"
LEFT JOIN "OITM" I  ON L."ItemCode" = I."ItemCode"
LEFT JOIN "OITB" G  ON I."ItmsGrpCod" = G."ItmsGrpCod"
LEFT JOIN "OMRC" M  ON I."FirmCode" = M."FirmCode"
LEFT JOIN "OSLP" S  ON V."SlpCode" = S."SlpCode"
LEFT JOIN "OSHP" SH ON V."TrnspCode" = SH."TrnspCode"
LEFT JOIN "OCRD" P  ON I."CardCode" = P."CardCode"

WHERE
    V."DocDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END

ORDER BY
    V."DocDate",
    V."DocNum",
    L."LineNum";