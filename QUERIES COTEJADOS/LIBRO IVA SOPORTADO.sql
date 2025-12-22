/****************************************************************************************
 LIBRO DE IVA SOPORTADO – SAP BUSINESS ONE (HANA)

 OBJETIVO:
 - Generar el CSV de IVA SOPORTADO con estructura fiscal estándar.
 - Basado en FACTURAS DE PROVEEDORES (OPCH + PCH1).
 - Una línea por documento y tipo impositivo.

 CONSIDERACIONES IMPORTANTES:
 - SAP B1 NO guarda explícitamente:
     • N/I, N/B, Tipo AUT → se dejan como columnas vacías.
     • Medio de pago detallado por línea → aproximado desde pagos.
 - El TOTAL DOCUM corresponde al total de la factura (no por tipo).
 - Fecha Pago / Importe Pago se obtienen desde pagos salientes (OVPM).
 - Cod.Imp. se toma desde OVTG (grupo de IVA).
****************************************************************************************/

SELECT
    C."DocEntry"                                AS "N.REGISTRO",

    TO_VARCHAR(C."DocDate", 'DD/MM/YYYY')       AS "FECHA",

    BP."FederalTaxID"                           AS "NIF/DNI",

    BP."CardName"                              AS "NOMBRE",

    SUM(L."LineTotal")                         AS "BASE IVA",

    T."Rate"                                   AS "TIPO",

    SUM(L."LineTotal" * T."Rate" / 100)        AS "CUOTA",

    C."DocTotal"                               AS "TOTAL DOCUM",

    'F'                                        AS "F/A",          -- Factura

    ''                                         AS "N/I",          -- No informado en B1

    ''                                         AS "N/B",          -- No informado en B1

    ''                                         AS "Tipo AUT",     -- No aplica

    C."NumAtCard"                              AS "S/factura",    -- Nº factura proveedor

    C."Comments"                               AS "Comentarios",

    BP."CardName"                              AS "Factura Directa a",

    TO_VARCHAR(P."DocDate", 'DD/MM/YYYY')      AS "Fecha Pago",

    P."DocTotal"                               AS "Importe Pago",

    P."CashAcct"                               AS "Medio Cuenta",

    T."Code"                                   AS "Cod.Imp.",

    T."Name"                                   AS "Descripción"

FROM "OPCH" C
         INNER JOIN "PCH1" L
                    ON C."DocEntry" = L."DocEntry"

         LEFT JOIN "OVTG" T
                   ON L."VatGroup" = T."Code"

         LEFT JOIN "OCRD" BP
                   ON C."CardCode" = BP."CardCode"

         LEFT JOIN "VPM2" P2
                   ON P2."DocEntry" = C."DocEntry"
                       AND P2."InvType" = 18               -- 18 = Factura proveedor

         LEFT JOIN "OVPM" P
                   ON P."DocEntry" = P2."DocNum"

WHERE
    C."DocDate" BETWEEN DATE '2025-10-01' AND DATE '2025-10-31'
  AND T."Rate" IS NOT NULL

GROUP BY
    C."DocEntry",
    C."DocDate",
    BP."FederalTaxID",
    BP."CardName",
    T."Rate",
    C."DocTotal",
    C."NumAtCard",
    C."Comments",
    P."DocDate",
    P."DocTotal",
    P."CashAcct",
    T."Code",
    T."Name"

ORDER BY
    C."DocDate",
    C."DocEntry",
    T."Rate";

/****************************************************************************************
 NOTAS FINALES:

 - El resultado está listo para exportarse directamente a CSV.
 - Si deseas:
     • Separar por proveedor → agregar BP.CardCode
     • Separar por factura → quitar el GROUP BY por tasa
     • Usar fecha contable → cambiar DocDate por TaxDate
 - Este modelo es compatible con Postman / Service Layer / Query Manager.
****************************************************************************************/
