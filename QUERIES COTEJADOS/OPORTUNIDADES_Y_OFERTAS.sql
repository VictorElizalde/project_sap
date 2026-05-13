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

    CASE
        WHEN C."QryGroup7"  = 'Y' THEN 'Hoteles'
        WHEN C."QryGroup8"  = 'Y' THEN 'Prof.Ind.'
        WHEN C."QryGroup9"  = 'Y' THEN 'Prom.Ind.'
        WHEN C."QryGroup10" = 'Y' THEN 'Financieras'
        WHEN C."QryGroup11" = 'Y' THEN 'Prom. Dir.'
        WHEN C."QryGroup12" = 'Y' THEN 'Export'
        WHEN C."QryGroup13" = 'Y' THEN 'Prof. Dir.'
        WHEN C."QryGroup14" = 'Y' THEN 'Empresa'
        ELSE ''
    END                                          AS "RAMO",

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
    COALESCE(Q."DocTotal" - Q."GrosProfit", 0)   AS "COSTE OFERTA",

    OPR."OpenDate"                               AS "FECHA DE CREACIÓN",
    OPR."CloseDate"                              AS "FECHA DE CIERRE",

    CASE OPR."Source"
        WHEN 1 THEN 'Llamada en frío'
        WHEN 2 THEN 'Campaña'
        WHEN 3 THEN 'Contacto directo'
        WHEN 4 THEN 'Recomendación'
        WHEN 5 THEN 'Email'
        WHEN 6 THEN 'Web'
        WHEN 7 THEN 'Otro'
        ELSE COALESCE(CAST(OPR."Source" AS VARCHAR(20)), '')
    END                                          AS "PROCEDENCIA",

    -- OFERTA
    Q."DocNum"                                   AS "Nº OFERTA",
    OPR."CardCode"                               AS "CLIENTE",
    COALESCE(C."CardName", '')                   AS "NOMBRE CLIENTE",
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
    COALESCE(I."AvgPrice", 0) * COALESCE(L."Quantity", 0) AS "COSTE TOTAL LÍNEA",

    CASE WHEN COALESCE(L."Price", 0) <> 0
         THEN ROUND((L."Price" - COALESCE(I."AvgPrice", 0)) / L."Price" * 100, 2)
         ELSE 0
    END                                          AS "% MARGEN UNIDAD",

    -- DIRECCIÓN DE ENTREGA
    COALESCE(Q."ShipToCode", '')                 AS "DIRECCIÓN DE ENTREGA"

FROM "OOPR" OPR
LEFT JOIN "OQUT" Q    ON Q."DocEntry"    = OPR."DocEntry"
                      AND OPR."DocType"  = '23'
LEFT JOIN "QUT1" L    ON Q."DocEntry"    = L."DocEntry"
LEFT JOIN "OCRD" C    ON OPR."CardCode"  = C."CardCode"
LEFT JOIN "OSLP" S    ON OPR."SlpCode"   = S."SlpCode"
LEFT JOIN "OITM" I    ON L."ItemCode"    = I."ItemCode"
LEFT JOIN "OITB" G    ON I."ItmsGrpCod"  = G."ItmsGrpCod"
LEFT JOIN "OMRC" MRC  ON I."FirmCode"    = MRC."FirmCode"

WHERE
    OPR."OpenDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND (OPR."Status" = '[%Estado%]' OR '[%Estado%]' = '')

UNION ALL

-- PART 2: Ofertas SIN oportunidad ligada
SELECT
    CASE Q."DocStatus"
        WHEN 'O' THEN 'Oferta Abierta'
        WHEN 'C' THEN 'Oferta Cerrada'
        ELSE Q."DocStatus"
    END                                          AS "STATUS",

    CASE
        WHEN C."QryGroup7"  = 'Y' THEN 'Hoteles'
        WHEN C."QryGroup8"  = 'Y' THEN 'Prof.Ind.'
        WHEN C."QryGroup9"  = 'Y' THEN 'Prom.Ind.'
        WHEN C."QryGroup10" = 'Y' THEN 'Financieras'
        WHEN C."QryGroup11" = 'Y' THEN 'Prom. Dir.'
        WHEN C."QryGroup12" = 'Y' THEN 'Export'
        WHEN C."QryGroup13" = 'Y' THEN 'Prof. Dir.'
        WHEN C."QryGroup14" = 'Y' THEN 'Empresa'
        ELSE ''
    END                                          AS "RAMO",

    COALESCE(S."SlpName", '')                    AS "COMERCIAL",
    ''                                           AS "NOMBRE DE LA OPORTUNIDAD",
    NULL                                         AS "Nº DE OPORTUNIDAD",
    NULL                                         AS "% CIERRE",
    NULL                                         AS "IMPORTE POTENCIAL",

    COALESCE(Q."GrosProfit", 0)                  AS "MARGEN",
    CASE WHEN COALESCE(Q."DocTotal", 0) <> 0
         THEN ROUND(Q."GrosProfit" / Q."DocTotal" * 100, 2)
         ELSE 0
    END                                          AS "% MARGEN",
    COALESCE(Q."DocTotal" - Q."GrosProfit", 0)   AS "COSTE OFERTA",

    Q."DocDate"                                  AS "FECHA DE CREACIÓN",
    Q."DocDueDate"                               AS "FECHA DE CIERRE",
    ''                                           AS "PROCEDENCIA",

    Q."DocNum"                                   AS "Nº OFERTA",
    Q."CardCode"                                 AS "CLIENTE",
    COALESCE(Q."CardName", '')                   AS "NOMBRE CLIENTE",
    Q."DocDate"                                  AS "FECHA OFERTA",

    COALESCE(MRC."FirmName", '')                 AS "MARCA",
    COALESCE(G."ItmsGrpNam", '')                 AS "GRUPO",
    COALESCE(I."U_GEST_Fam1", '')                AS "FAMILIA",
    COALESCE(I."U_GEST_Fam2", '')                AS "SUBFAMILIA",
    L."ItemCode"                                 AS "REFERENCIA",
    L."Dscription"                               AS "DESCRIPCIÓN",
    L."Quantity"                                 AS "CANTIDAD",
    L."Price"                                    AS "PRECIO POR UNIDAD",
    L."LineTotal"                                AS "PRECIO TOTAL",

    COALESCE(I."AvgPrice", 0)                    AS "COSTE UNIDAD",
    COALESCE(I."AvgPrice", 0) * COALESCE(L."Quantity", 0) AS "COSTE TOTAL LÍNEA",

    CASE WHEN COALESCE(L."Price", 0) <> 0
         THEN ROUND((L."Price" - COALESCE(I."AvgPrice", 0)) / L."Price" * 100, 2)
         ELSE 0
    END                                          AS "% MARGEN UNIDAD",

    COALESCE(Q."ShipToCode", '')                 AS "DIRECCIÓN DE ENTREGA"

FROM "OQUT" Q
LEFT JOIN "QUT1" L    ON Q."DocEntry"    = L."DocEntry"
LEFT JOIN "OCRD" C    ON Q."CardCode"    = C."CardCode"
LEFT JOIN "OSLP" S    ON Q."SlpCode"     = S."SlpCode"
LEFT JOIN "OITM" I    ON L."ItemCode"    = I."ItemCode"
LEFT JOIN "OITB" G    ON I."ItmsGrpCod"  = G."ItmsGrpCod"
LEFT JOIN "OMRC" MRC  ON I."FirmCode"    = MRC."FirmCode"

WHERE NOT EXISTS (
    SELECT 1 FROM "OOPR" OPR2
    WHERE OPR2."DocEntry" = Q."DocEntry"
      AND OPR2."DocType"  = '23'
)
AND Q."DocDate" BETWEEN
    CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
AND
    CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END

ORDER BY
    "Nº DE OPORTUNIDAD",
    "Nº OFERTA",
    "REFERENCIA";