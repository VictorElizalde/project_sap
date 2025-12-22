SELECT
    /* CLI-AG */
    G.GroupName                                  AS "CLI-AG",

    /* Nombre Cliente Agrupado */
    G.GroupName                                  AS "Nombre_Cliente_Agrupado",

    /* Fecha Factura */
    TO_VARCHAR(V.DocDate, 'DD/MM/YYYY')          AS "Fec.Fra.",

    /* Se (no estándar en SAP B1) */
    ''                                           AS "Se",

    /* Número de factura */
    V.DocNum                                     AS "Factur",

    /* Código cliente */
    C.CardCode                                   AS "CodCli",

    /* Nombre cliente */
    C.CardName                                   AS "Nombre_Cliente",

    /* Código dirección envío */
    COALESCE(A.Address, '')                      AS "CodD",

    /* Nombre dirección envío */
    COALESCE(A.Street, '')                       AS "Nombre_Dir_Envio",

    /* Importe neto (sin IVA) */
    SUM(L.LineTotal)                             AS "Imp.Neto",

    /* Nombre ramo (no estándar, se usa grupo cliente) */
    G.GroupName                                  AS "Nombre_Ramo",

    /* CodCli repetido (según CSV solicitado) */
    C.CardCode                                   AS "CodCli"

FROM OINV V
         INNER JOIN INV1 L
                    ON V.DocEntry = L.DocEntry

         INNER JOIN OCRD C
                    ON V.CardCode = C.CardCode

         LEFT JOIN OCRG G
                   ON C.GroupCode = G.GroupCode

/* Dirección de envío de la factura */
         LEFT JOIN INV12 A
                   ON V.DocEntry = A.DocEntry
                       AND A.AddrType = 'S'

WHERE
    V.DocDate BETWEEN :FechaInicio AND :FechaFin
  AND G.GroupName = 'CATALONIA'

GROUP BY
    G.GroupName,
    V.DocDate,
    V.DocNum,
    C.CardCode,
    C.CardName,
    A.Address,
    A.Street

ORDER BY
    C.CardName,
    V.DocNum;

/* =====================================================================================
   NOTAS FINALES
   -------------
   - Si no existe INV12 en tu versión, sustituir por:
       OCRD.Address / OCRD.MailAddress
   - Si "Ramo" o "CLI-AG" vienen de UDFs:
       sustituir G.GroupName por OCRD.U_xxx
   - Compatible con exportación directa a CSV
===================================================================================== */
