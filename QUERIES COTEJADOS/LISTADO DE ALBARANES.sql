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
    A."Street"                                   AS "Dirección destinatario",
    A."ZipCode"                                  AS "C.Postal destinatario",
    A."City"                                     AS "Población destinatario",
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
    ''                                           AS "Artículo",
    ''                                           AS "Descripción",
    ''                                           AS "Cantidad",
    ''                                           AS "Precio",
    ''                                           AS "Dtos.",
    ''                                           AS "Importe",

    -- COSTES (NO EXISTEN EN ALBARÁN)
    ''                                           AS "P.Coste",
    ''                                           AS "Imp.Coste",

    -- PROVEEDOR / FAMILIA
    ''                                           AS "Proveedor",
    ''                                           AS "Familia"

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

ORDER BY
    D."DocNum",
    L."LineNum";