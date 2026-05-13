SELECT
    ROW_NUMBER() OVER (ORDER BY "FECHA", "DOCUM") AS "N.REGISTRO",
    "FECHA",
    "NIF/DNI",
    "NOMBRE",
    "TIPO",
    "BASE IRPF",
    "%",
    "RETENCION",
    "TOTAL",
    "DOCUM"

FROM (

    -- -------------------------------------------------------
    -- FACTURAS DE COMPRA (OPCH + PCH5)
    -- -------------------------------------------------------
    SELECT
        O."TaxDate"                                  AS "FECHA",
        COALESCE(C."LicTradNum", '')                 AS "NIF/DNI",
        C."CardName"                                 AS "NOMBRE",
        WH."WTName"                                  AS "TIPO",
        W."TaxbleAmnt"                               AS "BASE IRPF",
        W."Rate"                                     AS "%",
        W."WTAmnt"                                   AS "RETENCION",
        O."DocTotal"                                 AS "TOTAL",
        O."DocNum"                                   AS "DOCUM"
    FROM "PCH5" W
    INNER JOIN "OPCH" O  ON W."AbsEntry" = O."DocEntry"
    INNER JOIN "OCRD" C  ON O."CardCode" = C."CardCode"
    INNER JOIN "OWHT" WH ON W."WTCode"   = WH."WTCode"
    WHERE
        O."TaxDate" BETWEEN
            CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
        AND
            CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
        AND W."Category" = 'I'

    UNION ALL

    -- -------------------------------------------------------
    -- ABONOS DE COMPRA (ORPC + RPC5) — importes negativos
    -- -------------------------------------------------------
    SELECT
        O."TaxDate",
        COALESCE(C."LicTradNum", ''),
        C."CardName",
        WH."WTName",
        -W."TaxbleAmnt",
        W."Rate",
        -W."WTAmnt",
        -O."DocTotal",
        O."DocNum"
    FROM "RPC5" W
    INNER JOIN "ORPC" O  ON W."AbsEntry" = O."DocEntry"
    INNER JOIN "OCRD" C  ON O."CardCode" = C."CardCode"
    INNER JOIN "OWHT" WH ON W."WTCode"   = WH."WTCode"
    WHERE
        O."TaxDate" BETWEEN
            CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
        AND
            CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
        AND W."Category" = 'I'

) T

ORDER BY "FECHA", "DOCUM";