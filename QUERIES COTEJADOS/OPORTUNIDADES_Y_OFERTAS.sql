-- ============================================================
-- OPORTUNIDADES Y OFERTAS
-- ------------------------------------------------------------
-- Descripción : Oportunidades CRM con sus ofertas vinculadas
--               y líneas de artículo. Incluye margen a nivel
--               de oportunidad/oferta y por línea.
-- Parámetros  : [%FechaDesde%] Fecha creación desde (opcional)
--               [%FechaHasta%] Fecha creación hasta  (opcional)
--               [%Estado%]     O=Abierta, W=Ganada, L=Perdida
--                              (opcional, vacío = todas)
-- Tablas      : OOPR, OQUT, QUT1, OCRD, OSLP, OCQG, OITM,
--               OITB, OMRC, CRD1
-- ============================================================
SELECT
    -- OPORTUNIDAD
    CASE OPR."Status"
        WHEN 'O' THEN 'Abierta'
        WHEN 'W' THEN 'Ganada'
        WHEN 'L' THEN 'Perdida'
        ELSE OPR."Status"
    END                                          AS "STATUS",

    COALESCE(QG."GroupName", '')                 AS "RAMO",
    COALESCE(S."SlpName", '')                    AS "COMERCIAL",
    OPR."Name"                                   AS "NOMBRE DE LA OPORTUNIDAD",
    OPR."OpprId"                                 AS "Nº DE OPORTUNIDAD",
    OPR."CloPrcnt"                               AS "% CIERRE",
    OPR."MaxSumLoc"                              AS "IMPORTE POTENCIAL",

    COALESCE(Q."GrosProfit", 0)                  AS "MARGEN",
    CASE WHEN COALESCE(Q."DocTotal", 0) <> 0
         THEN ROUND(Q."GrosProfit" / Q."DocTotal" * 100, 2)
         ELSE 0
    END                                          AS "% MARGEN",

    OPR."OpenDate"                               AS "FECHA DE CREACIÓN",
    OPR."CloseDate"                              AS "FECHA DE CIERRE",
    OPR."Source"                                 AS "PROCEDENCIA",

    -- OFERTA
    Q."DocNum"                                   AS "Nº OFERTA",
    OPR."CardCode"                               AS "CLIENTE",
    Q."DocDate"                                  AS "FECHA OFERTA",

    -- ARTÍCULO
    COALESCE(MRC."FirmName", '')                 AS "MARCA",
    COALESCE(G."ItmsGrpNam", '')                 AS "GRUPO",
    COALESCE(I."U_GEST_Fam1", '')                AS "FAMILIA",
    COALESCE(I."U_GEST_Fam2", '')                AS "SUBFAMILIA",
    L."ItemCode"                                 AS "REFERENCIA",
    L."Dscription"                               AS "DESCRIPCIÓN",
    L."Quantity"                                 AS "CANTIDAD",
    L."Price"                                    AS "PRECIO POR UNIDAD",
    L."LineTotal"                                AS "PRECIO TOTAL",

    -- COSTES Y MARGEN POR LÍNEA
    COALESCE(I."AvgPrice", 0)                    AS "COSTE UNIDAD",
    COALESCE(I."AvgPrice", 0) * L."Quantity"     AS "COSTE TOTAL",

    CASE WHEN L."Price" <> 0
         THEN ROUND((L."Price" - COALESCE(I."AvgPrice", 0)) / L."Price" * 100, 2)
         ELSE 0
    END                                          AS "% MARGEN UNIDAD",

    -- DIRECCIÓN DE ENTREGA
    COALESCE(ADDR."Street", '')                  AS "DIRECCIÓN DE ENTREGA"

FROM "OOPR" OPR
LEFT JOIN "OQUT" Q    ON Q."DocEntry"    = OPR."DocEntry"
                      AND OPR."DocType"  = '17'
LEFT JOIN "QUT1" L    ON Q."DocEntry"    = L."DocEntry"
LEFT JOIN "OCRD" C    ON OPR."CardCode"  = C."CardCode"
LEFT JOIN "OSLP" S    ON OPR."SlpCode"   = S."SlpCode"
LEFT JOIN "OCQG" QG   ON C."GroupCode"   = QG."GroupCode"
LEFT JOIN "OITM" I    ON L."ItemCode"    = I."ItemCode"
LEFT JOIN "OITB" G    ON I."ItmsGrpCod"  = G."ItmsGrpCod"
LEFT JOIN "OMRC" MRC  ON I."FirmCode"    = MRC."FirmCode"
LEFT JOIN "CRD1" ADDR ON Q."CardCode"    = ADDR."CardCode"
                      AND ADDR."AdresType" = 'S'
                      AND ADDR."Address"   = Q."ShipToCode"

WHERE
    OPR."OpenDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND (OPR."Status" = '[%Estado%]' OR '[%Estado%]' = '')

ORDER BY
    OPR."OpprId",
    Q."DocNum",
    L."LineNum";

