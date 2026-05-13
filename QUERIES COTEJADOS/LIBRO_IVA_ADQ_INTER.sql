SELECT
    ROW_NUMBER() OVER (ORDER BY "Fecha Contable", "DOCUM", "TIPO") AS "N.REGISTRO",
    "Fecha Contable"    AS "FECHA",
    "NIF/DNI",
    "NOMBRE",
    "BASE IVA",
    "TIPO",
    "CUOTA",
    "TOTAL",
    "DOCUM",
    "F/A",
    "Env/SII"

FROM (

    -- -------------------------------------------------------
    -- FACTURAS DE COMPRA (OPCH)
    -- -------------------------------------------------------
    SELECT
        O."TaxDate"                                  AS "Fecha Contable",
        COALESCE(C."LicTradNum", '')                 AS "NIF/DNI",
        C."CardName"                                 AS "NOMBRE",
        SUM(L."LineTotal")                           AS "BASE IVA",
        L."VatPrcnt"                                 AS "TIPO",
        SUM(L."VatSum")                              AS "CUOTA",
        SUM(L."LineTotal") + SUM(L."VatSum")         AS "TOTAL",
        O."DocNum"                                   AS "DOCUM",
        'F'                                          AS "F/A",
        COALESCE(O."U_GEI_Env", '')                  AS "Env/SII"
    FROM "OPCH" O
    INNER JOIN "PCH1" L ON O."DocEntry" = L."DocEntry"
    INNER JOIN "OCRD" C ON O."CardCode" = C."CardCode"
    WHERE
        O."TaxDate" BETWEEN
            CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
        AND
            CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
        AND C."Country" IN (
            'AT','BE','BG','CY','CZ','DE','DK','EE','FI','FR',
            'GR','HR','HU','IE','IT','LT','LU','LV','MT','NL',
            'PL','PT','RO','SE','SI','SK'
        )
    GROUP BY
        O."TaxDate", O."DocNum", C."LicTradNum", C."CardName",
        L."VatPrcnt", O."U_GEI_Env"

    UNION ALL

    -- -------------------------------------------------------
    -- ABONOS DE COMPRA (ORPC) — importes negativos
    -- -------------------------------------------------------
    SELECT
        O."TaxDate",
        COALESCE(C."LicTradNum", ''),
        C."CardName",
        -SUM(L."LineTotal"),
        L."VatPrcnt",
        -SUM(L."VatSum"),
        -(SUM(L."LineTotal") + SUM(L."VatSum")),
        O."DocNum",
        'A',
        COALESCE(O."U_GEI_Env", '')
    FROM "ORPC" O
    INNER JOIN "RPC1" L ON O."DocEntry" = L."DocEntry"
    INNER JOIN "OCRD" C ON O."CardCode" = C."CardCode"
    WHERE
        O."TaxDate" BETWEEN
            CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
        AND
            CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
        AND C."Country" IN (
            'AT','BE','BG','CY','CZ','DE','DK','EE','FI','FR',
            'GR','HR','HU','IE','IT','LT','LU','LV','MT','NL',
            'PL','PT','RO','SE','SI','SK'
        )
    GROUP BY
        O."TaxDate", O."DocNum", C."LicTradNum", C."CardName",
        L."VatPrcnt", O."U_GEI_Env"

) T

ORDER BY "Fecha Contable", "DOCUM", "TIPO";