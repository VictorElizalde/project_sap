-- ============================================================
-- INVENTARIO
-- ------------------------------------------------------------
-- Descripción : Stock por artículo y almacén a una fecha dada.
--               Muestra disponible, comprometido, pendiente de
--               recibir, entregas abiertas y antigüedad (FIFO).
-- Parámetros  : [%0%] Fecha de corte (DD/MM/YYYY). Si se deja
--               vacío se usa la fecha actual.
-- Tablas      : OITM, OITW, OITB, OMRC, OINM, DLN1, POR1
-- ============================================================
SELECT
    -- Marca
    IFNULL(MRC."FirmName", '-')                 AS "MARCA",

    -- Grupo
    G."ItmsGrpNam"                              AS "GRUPO",

    -- Familias
    I."U_GEST_Fam1"                             AS "FAMILIA",
    I."U_GEST_Fam2"                             AS "SUBFAMILIA",

    -- Artículo
    I."ItemCode"                                 AS "ARTICULO",
    I."ItemName"                                AS "DESCRIPCION",

    -- Depósito
    W."WhsCode"                                 AS "DEPOSITO",

    -- Precio medio de compra (valoración por almacén)
    COALESCE(W."AvgPrice", 0)                   AS "PRECIO MEDIO",

    -- Disponible al cierre de la fecha indicada
    COALESCE(
        (SELECT SUM("InQty" - "OutQty")
         FROM "OINM" m
         WHERE m."ItemCode" = I."ItemCode"
           AND m."Warehouse" = W."WhsCode"
           AND m."DocDate"  <= COALESCE(TO_DATE(NULLIF(SUBSTRING('[%0%]', 1, 10), ''), 'YYYY-MM-DD'), CURRENT_DATE))
     , 0)                                        - W."IsCommited" AS "DISPONIBLE",

    -- Stock al cierre de la fecha indicada
    COALESCE(
        (SELECT SUM("InQty" - "OutQty")
         FROM "OINM" m
         WHERE m."ItemCode" = I."ItemCode"
           AND m."Warehouse" = W."WhsCode"
           AND m."DocDate"  <= COALESCE(TO_DATE(NULLIF(SUBSTRING('[%0%]', 1, 10), ''), 'YYYY-MM-DD'), CURRENT_DATE))
     , 0)                                        AS "CANTIDAD",

    -- Comprometido (valor actual)
    W."IsCommited"                              AS "COMPROMETIDO",

    -- Pendiente de recibir (solo pedidos de compra abiertos)
    IFNULL(P."PT_RECIBIR", 0)                  AS "PT.RECIBIR",

    -- Disponible futuro (valor actual)
    (W."OnHand" - W."IsCommited" + W."OnOrder") AS "DISPON.FUTURO",

    -- Entregas abiertas
    IFNULL(E."ENTREGAS", 0)                     AS "ENTREGAS",

    -- Stock por tramo de antigüedad FIFO
    -- Se acumulan entradas de más reciente a más antigua hasta cubrir el OnHand actual.
    -- Cada unidad se asigna al tramo según la fecha de su lote de entrada.
    COALESCE(CAST(F."STOCK_0_30"  AS INTEGER), 0) AS "STOCK 0-30",
    COALESCE(CAST(F."STOCK_31_60" AS INTEGER), 0) AS "STOCK 31-60",
    COALESCE(CAST(F."STOCK_61_90" AS INTEGER), 0) AS "STOCK 61-90",
    COALESCE(CAST(F."STOCK_90"    AS INTEGER), 0) AS "STOCK +90"

FROM "OITM" I
    JOIN  "OITW" W   ON I."ItemCode"   = W."ItemCode"
    JOIN  "OITB" G   ON I."ItmsGrpCod" = G."ItmsGrpCod"
    LEFT JOIN "OMRC" MRC ON I."FirmCode" = MRC."FirmCode"

    -- Stock por tramo de antigüedad FIFO
    -- Lógica: acumular InQty de más reciente a más antigua; solo se cuenta
    -- la porción de cada lote que aún "cabe" dentro del stock actual (OnHand).
    LEFT JOIN (
        SELECT
            "ItemCode",
            "Warehouse",
            SUM(CASE WHEN DAYS_BETWEEN("DocDate", CURRENT_DATE) <= 30
                     THEN "LoteEfectivo" ELSE 0 END) AS "STOCK_0_30",
            SUM(CASE WHEN DAYS_BETWEEN("DocDate", CURRENT_DATE) BETWEEN 31 AND 60
                     THEN "LoteEfectivo" ELSE 0 END) AS "STOCK_31_60",
            SUM(CASE WHEN DAYS_BETWEEN("DocDate", CURRENT_DATE) BETWEEN 61 AND 90
                     THEN "LoteEfectivo" ELSE 0 END) AS "STOCK_61_90",
            SUM(CASE WHEN DAYS_BETWEEN("DocDate", CURRENT_DATE) > 90
                     THEN "LoteEfectivo" ELSE 0 END) AS "STOCK_90"
        FROM (
            -- Para cada lote de entrada, calcular cuántas unidades de ese lote
            -- siguen en stock (criterio FIFO: se consumen primero los más antiguos,
            -- por lo que los más recientes son los que "quedan").
            SELECT
                "ItemCode",
                "Warehouse",
                "DocDate",
                -- Unidades efectivas del lote que aún están en stock:
                -- = min(InQty del lote, max(0, StockActual - acumulado_anterior))
                GREATEST(0,
                    LEAST(
                        "InQty",
                        "StockActual" - ("AcumDesc" - "InQty")
                    )
                ) AS "LoteEfectivo"
            FROM (
                SELECT
                    e."ItemCode",
                    e."Warehouse",
                    e."DocDate",
                    e."InQty",
                    w2."OnHand" AS "StockActual",
                    -- Acumulado descendente (de más reciente a más antigua)
                    SUM(e."InQty") OVER (
                        PARTITION BY e."ItemCode", e."Warehouse"
                        ORDER BY e."DocDate" DESC, e."TransNum" DESC
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                    ) AS "AcumDesc"
                FROM "OINM" e
                JOIN "OITW" w2
                  ON e."ItemCode"  = w2."ItemCode"
                 AND e."Warehouse" = w2."WhsCode"
                WHERE e."InQty" > 0
                  AND w2."OnHand" > 0
            ) X
            -- Solo lotes que aún aportan stock (acumulado anterior < stock actual)
            WHERE ("AcumDesc" - "InQty") < "StockActual"
        ) Y
        GROUP BY "ItemCode", "Warehouse"
    ) F ON I."ItemCode" = F."ItemCode"
       AND W."WhsCode"  = F."Warehouse"

    -- Entregas abiertas (por almacén)
    LEFT JOIN (
        SELECT
            "ItemCode",
            "WhsCode",
            SUM("OpenQty") AS "ENTREGAS"
        FROM "DLN1"
        WHERE "LineStatus" = 'O'
        GROUP BY "ItemCode", "WhsCode"
    ) E ON I."ItemCode" = E."ItemCode"
       AND W."WhsCode"  = E."WhsCode"

    -- Pendiente de recibir (pedidos de compra abiertos, por almacén)
    LEFT JOIN (
        SELECT
            "ItemCode",
            "WhsCode",
            SUM("OpenQty") AS "PT_RECIBIR"
        FROM "POR1"
        WHERE "LineStatus" = 'O'
        GROUP BY "ItemCode", "WhsCode"
    ) P ON I."ItemCode" = P."ItemCode"
       AND W."WhsCode"  = P."WhsCode"

WHERE
    (W."OnHand"        <> 0
     OR W."IsCommited" <> 0
     OR W."OnOrder"    <> 0)

ORDER BY
    I."U_GEST_Fam1",
    I."U_GEST_Fam2",
    MRC."FirmName",
    I."ItemCode",
    W."WhsCode";