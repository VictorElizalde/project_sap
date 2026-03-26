-- ============================================================
-- LISTADO DE ALBARANES
-- ------------------------------------------------------------
-- Descripción : Listado de albaranes abiertos con sus líneas.
--               Incluye pedido base, cliente, dirección de
--               envío completa (provincia/país por nombre),
--               transportista y ramo del cliente.
-- Parámetros  : Ninguno (filtra DocStatus = 'O')
-- Tablas      : ODLN, DLN1, ORDR, OCRD, CRD1, OITM, DLN12,
--               OCRY, OCST, OSHP, OCQG
-- ============================================================
SELECT
    -- DOCUMENTO
    D."DocNum"                                   AS "Núm.Albarán",
    TO_VARCHAR(D."DocDate",'DD/MM/YYYY')         AS "Fecha Albarán",
    'ALBARÁN'                                    AS "Tipo",

    -- PEDIDO BASE
    COALESCE(O."DocNum", NULL)                   AS "Código Pedido",
    TO_VARCHAR(O."DocDate",'DD/MM/YYYY')         AS "Fecha Pedido",
    COALESCE(O."NumAtCard", NULL)                AS "Referencia Pedido",

    -- COMERCIAL / CLIENTE
    D."SlpCode"                                  AS "Agente",
    D."CardCode"                                 AS "Cliente",
    C."CardName"                                 AS "Nombre Fiscal",
    D."CardName"                                 AS "Nombre destinatario",

    -- DIRECCIÓN
    D."ShipToCode"                               AS "Dirección destinatario",
    DL."ZipCodeS"                                 AS "C.Postal destinatario",
    DL."CityS"                                    AS "Población destinatario",
    COALESCE(CST."Name", DL."StateS")            AS "Provincia destinatario",
    COALESCE(CRY."Name", DL."CountryS")          AS "País destinatario",

    -- DATOS FISCALES
    C."LicTradNum"                               AS "CIF destinatario",
    A."U_Phone1"                                 AS "Teléfono destinatario",

    -- OBSERVACIONES
    A."GlblLocNum"                               AS "Obs.destinatario",

    -- LOGÍSTICA
    ''                                           AS "Portes",
    ''                                           AS "Valorado",

    T."TrnspName"                                AS "Enviado por",
    CAST(NULL AS NVARCHAR(20))                   AS "Sit.Impr.",
    CAST(NULL AS NVARCHAR(20))                   AS "Sit.Exp.",
    CAST(NULL AS NVARCHAR(20))                   AS "Sit.Conf.",

    -- FECHAS / CONDICIONES
    L."WhsCode"                                  AS "Depósito",
    C."GroupNum"                                 AS "F.Pago",
    D."DocDueDate"                               AS "F.Entrega",
    D."TaxDate"                                  AS "F.Valor",

    -- DESCUENTOS
    L."DiscPrcnt"                                AS "Dto.1",
    0                                            AS "Dto.2",
    0                                            AS "Dto.3",
    0                                            AS "Dto.PP",
    0                                            AS "Gtos.Fin.",

    -- ARTÍCULOS
    COALESCE(QG."GroupName", '')                 AS "Ramo",
    L."ItemCode"                                 AS "Artículo",
    L."Dscription"                               AS "Descripción",
    L."Quantity"                                 AS "Cantidad",
    L."Price"                                    AS "Precio",
    L."DiscPrcnt"                                AS "Dtos.",
    L."LineTotal"                                AS "Importe",

    -- COSTES (NO EXISTEN EN ALBARÁN)
    0                                            AS "P.Coste",
    0                                            AS "Imp.Coste",

    -- PROVEEDOR / FAMILIA
    CAST(NULL AS NVARCHAR(100))                  AS "Proveedor",
    I."ItmsGrpCod"                               AS "Familia"

FROM "ODLN" D
JOIN "DLN1" L
  ON D."DocEntry" = L."DocEntry"

LEFT JOIN "ORDR" O
  ON O."DocEntry" = L."BaseEntry"
 AND L."BaseType" = 17

LEFT JOIN "OCRD" C
  ON D."CardCode" = C."CardCode"

LEFT JOIN "CRD1" A
  ON C."CardCode" = A."CardCode"
 AND A."AdresType" = 'S'
 AND A."Address" = D."ShipToCode"

LEFT JOIN "OITM" I
  ON L."ItemCode" = I."ItemCode"

LEFT JOIN "DLN12" DL ON D."DocEntry" = DL."DocEntry"
LEFT JOIN "OCRY" CRY ON DL."CountryS" = CRY."Code"
LEFT JOIN "OCST" CST ON DL."StateS" = CST."Code" AND DL."CountryS" = CST."Country"
LEFT JOIN "OSHP" T ON D."TrnspCode" = T."TrnspCode"
LEFT JOIN "OCQG" QG ON C."GroupCode" = QG."GroupCode"

WHERE
    D."DocStatus" = 'O'
    AND D."DocDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND (
        LOCATE(',' || D."CardCode" || ',', ',' || '[%Cliente%]' || ',') > 0
        OR '[%Cliente%]' = ''
    )

ORDER BY
    D."DocNum",
    L."LineNum";