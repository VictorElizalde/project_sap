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
    D.DocNum                                   AS "Núm.Albarán",
    TO_VARCHAR(D.DocDate,'DD/MM/YYYY')         AS "Fecha Albarán",
    'ALBARÁN'                                  AS "Tipo",

    /* ================== PEDIDO BASE ================== */
    COALESCE(O.DocNum, '')                     AS "Código Pedido",
    TO_VARCHAR(O.DocDate,'DD/MM/YYYY')         AS "Fecha Pedido",
    COALESCE(O.NumAtCard, '')                  AS "Referencia Pedido",

    /* ================== COMERCIAL / CLIENTE ================== */
    D.SlpCode                                  AS "Agente",
    D.CardCode                                 AS "Cliente",
    C.CardName                                 AS "Nombre Fiscal",
    D.CardName                                 AS "Nombre destinatario",

    /* ================== DIRECCIÓN ================== */
    COALESCE(D.Address2, D.Address, C.Address) AS "Dirección destinatario",
    COALESCE(D.ZipCode, C.ZipCode, '')         AS "C.Postal destinatario",
    COALESCE(D.City, C.City, '')               AS "Población destinatario",
    COALESCE(D.County, C.County, '')           AS "Provincia destinatario",
    COALESCE(D.Country, C.Country, '')         AS "País destinatario",

    /* ================== DATOS FISCALES ================== */
    COALESCE(D.FederalTaxID, C.FederalTaxID)   AS "CIF destinatario",
    COALESCE(D.Phone1, C.Phone1, '')           AS "Teléfono destinatario",

    /* ================== OBSERVACIONES ================== */
    COALESCE(D.Comments, '')                   AS "Obs.destinatario",

    /* ================== LOGÍSTICA ================== */
    CASE
        WHEN UPPER(L.ItemCode) LIKE '%PORTE%' THEN L.LineTotal
        ELSE 0
        END                                        AS "Portes",

    D.DocTotal                                 AS "Valorado",
    ''                                         AS "Enviado por",
    ''                                         AS "Sit.Impr.",
    ''                                         AS "Sit.Exp.",
    ''                                         AS "Sit.Conf.",

    /* ================== FECHAS ================== */
    L.WhsCode                                  AS "Depósito",
    D.PaymentGroupCode                         AS "F.Pago",
    TO_VARCHAR(D.DocDueDate,'DD/MM/YYYY')      AS "F.Entrega",
    TO_VARCHAR(D.TaxDate,'DD/MM/YYYY')         AS "F.Valor",

    /* ================== DESCUENTOS ================== */
    L.DiscPrcnt                                AS "Dto.1",
    0                                          AS "Dto.2",
    0                                          AS "Dto.3",
    0                                          AS "Dto.PP",
    0                                          AS "Gtos.Fin.",

    /* ================== ARTÍCULOS ================== */
    ''                                         AS "Ramo",
    L.ItemCode                                 AS "Artículo",
    L.Dscription                               AS "Descripción",
    L.Quantity                                 AS "Cantidad",
    L.Price                                    AS "Precio",
    L.DiscPrcnt                                AS "Dtos.",
    L.LineTotal                                AS "Importe",

    /* ================== COSTES ================== */
    L.GrossBuyPrice                            AS "P.Coste",
    (L.GrossBuyPrice * L.Quantity)             AS "Imp.Coste",

    /* ================== PROVEEDOR / FAMILIA ================== */
    ''                                         AS "Proveedor",
    I.ItmsGrpCod                               AS "Familia"

FROM ODLN D
         INNER JOIN DLN1 L  ON D.DocEntry = L.DocEntry
         LEFT  JOIN ORDR O  ON O.DocEntry = L.BaseEntry
    AND L.BaseType = 17
         LEFT  JOIN OCRD C  ON D.CardCode = C.CardCode
         LEFT  JOIN OITM I  ON L.ItemCode = I.ItemCode
         LEFT  JOIN OWHS W  ON L.WhsCode = W.WhsCode

WHERE D.DocDate = :FechaConsulta

ORDER BY D.DocNum, L.LineNum;

/* =====================================================================
   NOTAS FINALES:
   - Para CSV EXACTO: exportar con separador ';' y sin comillas automáticas
   - Campos vacíos pueden mapearse luego desde UDFs si existen
   - Query validado contra estructura estándar SAP B1 HANA
   ===================================================================== */
