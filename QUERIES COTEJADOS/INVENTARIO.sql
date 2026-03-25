SELECT
    -- Marca
    IFNULL(MRC."FirmName", '-')                 AS "MARCA",

    -- Grupo
    G."ItmsGrpNam"                              AS "GRUPO",

    -- Familias
    I."U_GEST_Fam1"                             AS "FAMILIA",
    I."U_GEST_Fam2"                             AS "SUBFAMILIA",

    -- Artículo
    I."ItemCode"                                AS "ARTICULO",
    I."ItemName"                                AS "DESCRIPCION",

    -- Depósito
    W."WhsCode"                                 AS "DEPOSITO",

    -- Disponible al cierre de la fecha indicada
    COALESCE(
        (SELECT SUM("InQty" - "OutQty")
         FROM "OINM" m
         WHERE m."ItemCode" = I."ItemCode"
           AND m."Warehouse" = W."WhsCode"
           AND m."DocDate"  <= CASE WHEN '[%0%]' = '' THEN CURRENT_DATE ELSE CAST(SUBSTRING('[%0%]', 1, 10) AS DATE) END)
    , 0)                                        - W."IsCommited" AS "DISPONIBLE",

    -- Stock al cierre de la fecha indicada
    COALESCE(
        (SELECT SUM("InQty" - "OutQty")
         FROM "OINM" m
         WHERE m."ItemCode" = I."ItemCode"
           AND m."Warehouse" = W."WhsCode"
           AND m."DocDate"  <= CASE WHEN '[%0%]' = '' THEN CURRENT_DATE ELSE CAST(SUBSTRING('[%0%]', 1, 10) AS DATE) END)
    , 0)                                        AS "CANTIDAD",

    -- Comprometido (valor actual)
    W."IsCommited"                              AS "COMPROMETIDO",

    -- Pendiente de recibir (solo pedidos de compra abiertos)
    IFNULL(P."PT_RECIBIR", 0)                  AS "PT.RECIBIR",

    -- Disponible futuro (valor actual)
    (W."OnHand" - W."IsCommited" + W."OnOrder") AS "DISPON.FUTURO",

    -- Entregas abiertas
    IFNULL(E."ENTREGAS", 0)                     AS "ENTREGAS",

    -- Antigüedad (desde la entrada más antigua, criterio FIFO)
    CASE
        WHEN DAYS_BETWEEN(M."PrimerEntrada", CURRENT_DATE) <= 30  THEN '0-30'
        WHEN DAYS_BETWEEN(M."PrimerEntrada", CURRENT_DATE) <= 60  THEN '31-60'
        WHEN DAYS_BETWEEN(M."PrimerEntrada", CURRENT_DATE) <= 90  THEN '61-90'
        ELSE '+90'
    END                                         AS "ANTIGÜEDAD",

    -- Rango de fechas de entrada
    M."PrimerEntrada"                           AS "FECHA 1RA.ENTRADA",
    M."UltEntrada"                              AS "FECHA ULT.ENTRADA"

FROM "OITM" I
    JOIN  "OITW" W   ON I."ItemCode"   = W."ItemCode"
    JOIN  "OITB" G   ON I."ItmsGrpCod" = G."ItmsGrpCod"
    LEFT JOIN "OMRC" MRC ON I."FirmCode" = MRC."FirmCode"

    -- Primera y última entrada por artículo y almacén
    LEFT JOIN (
        SELECT
            "ItemCode",
            "Warehouse",
            MIN("DocDate") AS "PrimerEntrada",
            MAX("DocDate") AS "UltEntrada"
        FROM "OINM"
        WHERE "InQty" > 0
        GROUP BY "ItemCode", "Warehouse"
    ) M ON I."ItemCode" = M."ItemCode"
       AND W."WhsCode"  = M."Warehouse"

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