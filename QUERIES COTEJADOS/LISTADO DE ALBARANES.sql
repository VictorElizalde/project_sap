/* =====================================================================
   LISTADO DE ALBARANES CLIENTES (por día) – SAP B1 HANA
   ---------------------------------------------------------------------
   CONSIDERACIONES IMPORTANTES:
   1) SAP B1 NO soporta JOINs complejos vía Service Layer → este SQL
      es para Query Manager / HANA Studio / DataGrip.
   2) Campos como:
      - Sit.Impr / Sit.Exp / Sit.Conf
      - Enviado por
      - Ramo
      - Gtos.Fin.
      suelen ser UDFs o externos → aquí se dejan como ''.
   3) Dirección / CP / Ciudad / País:
      se toman del albarán; si no existen, del cliente.
   4) Costes:
      P.Coste / Imp.Coste se calculan desde GrossBuyPrice cuando existe.
   ===================================================================== */
SELECT
    /* ================== DOCUMENTO ================== */
    D."DocNum"                                   AS "Núm.Albarán",
    TO_VARCHAR(D."DocDate",'DD/MM/YYYY')         AS "Fecha Albarán",
    'ALBARÁN'                                    AS "Tipo",

    /* ================== PEDIDO BASE ================== */
    COALESCE(O."DocNum", NULL)                   AS "Código Pedido",
    TO_VARCHAR(O."DocDate",'DD/MM/YYYY')         AS "Fecha Pedido",
    COALESCE(O."NumAtCard", NULL)                AS "Referencia Pedido",

    /* ================== COMERCIAL / CLIENTE ================== */
    D."SlpCode"                                  AS "Agente",
    D."CardCode"                                 AS "Cliente",
    C."CardName"                                 AS "Nombre Fiscal",
    D."CardName"                                 AS "Nombre destinatario",

    /* ================== DIRECCIÓN ================== */
    COALESCE(D."Address2", D."Address")          AS "Dirección destinatario",
    C."ZipCode"                                  AS "C.Postal destinatario",
    C."City"                                     AS "Población destinatario",
    C."County"                                   AS "Provincia destinatario",
    C."Country"                                  AS "País destinatario",

    /* ================== DATOS FISCALES ================== */
    C."LicTradNum"                               AS "CIF destinatario",
    C."Phone1"                                   AS "Teléfono destinatario",

    /* ================== OBSERVACIONES ================== */
    D."Comments"                                 AS "Obs.destinatario",

    /* ================== LOGÍSTICA ================== */
    CASE
        WHEN UPPER(L."ItemCode") LIKE '%PORTE%' THEN L."LineTotal"
        ELSE 0
        END                                          AS "Portes",

    D."DocTotal"                                 AS "Valorado",

    CAST(NULL AS NVARCHAR(50))                   AS "Enviado por",
    CAST(NULL AS NVARCHAR(20))                   AS "Sit.Impr.",
    CAST(NULL AS NVARCHAR(20))                   AS "Sit.Exp.",
    CAST(NULL AS NVARCHAR(20))                   AS "Sit.Conf.",

    /* ================== FECHAS / CONDICIONES ================== */
    L."WhsCode"                                  AS "Depósito",
    C."GroupNum"                                 AS "F.Pago",
    D."DocDueDate"                               AS "F.Entrega",
    D."TaxDate"                                  AS "F.Valor",

    /* ================== DESCUENTOS ================== */
    L."DiscPrcnt"                                AS "Dto.1",
    0                                            AS "Dto.2",
    0                                            AS "Dto.3",
    0                                            AS "Dto.PP",
    0                                            AS "Gtos.Fin.",

    /* ================== ARTÍCULOS ================== */
    CAST(NULL AS NVARCHAR(50))                   AS "Ramo",
    L."ItemCode"                                 AS "Artículo",
    L."Dscription"                               AS "Descripción",
    L."Quantity"                                 AS "Cantidad",
    L."Price"                                    AS "Precio",
    L."DiscPrcnt"                                AS "Dtos.",
    L."LineTotal"                                AS "Importe",

    /* ================== COSTES (NO EXISTEN EN ALBARÁN) ================== */
    0                                            AS "P.Coste",
    0                                            AS "Imp.Coste",

    /* ================== PROVEEDOR / FAMILIA ================== */
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

         LEFT JOIN "OITM" I
                   ON L."ItemCode" = I."ItemCode"

WHERE
    D."DocDate" >= DATE '2025-01-01'
  AND D."DocDate" <  DATE '2026-01-01'

ORDER BY
    D."DocNum",
    L."LineNum";

/* =====================================================================
 NOTAS FINALES:
 - Evita campos inexistentes en ODLN (ZipCode, Phone, FederalTaxID, etc.)
 - Dirección y fiscalidad desde OCRD (estándar)
 - Listo para Query Manager / DataGrip / CSV
 ===================================================================== */
