SELECT
    -- Grupo / Familia
    G."ItmsGrpCod"                    AS "GRUPO",
    G."ItmsGrpNam"                    AS "NOMBRE GRUPO",

    -- Artículo
    I."ItemCode"                      AS "ARTICULO",
    I."ItemName"                      AS "DESCRIPCION",

    -- Depósito
    W."WhsCode"                       AS "DEPOSITO",

    -- Stock
    W."OnHand"                        AS "CANTIDAD",

    -- Comprometido (pedidos cliente)
    W."IsCommited"                   AS "COMPROMETIDO",

    -- Pendiente de recibir
    W."OnOrder"                      AS "PT.RECIBIR",

    -- Disponible futuro
    (W."OnHand" - W."IsCommited" + W."OnOrder") AS "DISPON.FUTURO",

    -- Entregas abiertas
    IFNULL(E."ENTREGAS", 0)           AS "ENTREGAS",

    -- Antigüedad
    CASE
        WHEN DAYS_BETWEEN(M."UltEntrada", CURRENT_DATE) <= 30 THEN '0-30'
        WHEN DAYS_BETWEEN(M."UltEntrada", CURRENT_DATE) <= 60 THEN '31-60'
        WHEN DAYS_BETWEEN(M."UltEntrada", CURRENT_DATE) <= 90 THEN '61-90'
        ELSE '+90'
        END                               AS "ANTIGÜEDAD",

    -- Fecha última entrada
    M."UltEntrada"                   AS "FECHA ULT.ENTRADA"

FROM "OITM" I
         JOIN "OITW" W ON I."ItemCode" = W."ItemCode"
         JOIN "OITB" G ON I."ItmsGrpCod" = G."ItmsGrpCod"

-- Última entrada por artículo y almacén
         LEFT JOIN (
    SELECT
        "ItemCode",
        "Warehouse",
        MAX("DocDate") AS "UltEntrada"
    FROM "OINM"
    WHERE "InQty" > 0
    GROUP BY "ItemCode", "Warehouse"
) M ON I."ItemCode" = M."ItemCode"
    AND W."WhsCode" = M."Warehouse"

-- Entregas abiertas
         LEFT JOIN (
    SELECT
        "ItemCode",
        SUM("OpenQty") AS "ENTREGAS"
    FROM "DLN1"
    WHERE "LineStatus" = 'O'
    GROUP BY "ItemCode"
) E ON I."ItemCode" = E."ItemCode"

WHERE
    (W."OnHand" <> 0
        OR W."IsCommited" <> 0
        OR W."OnOrder" <> 0)

ORDER BY
    G."ItmsGrpNam",
    I."ItemCode",
    W."WhsCode";
