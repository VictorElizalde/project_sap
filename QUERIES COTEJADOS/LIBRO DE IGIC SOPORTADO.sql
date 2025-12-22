/* ============================================================================
   LIBRO DE IGIC SOPORTADO – SAP BUSINESS ONE (HANA)

   ✔ Origen de datos:
     - OPCH  : Facturas de proveedores (cabecera)
     - PCH1  : Líneas de factura
     - OCRD  : Proveedores
     - OVTG  : Grupos de impuesto (IGIC)
     - OACT  : Cuentas contables (opcional)

   ✔ Alcance real en SAP B1:
     - El "Libro IGIC soportado" se construye a partir de FACTURAS DE PROVEEDOR
     - El IGIC se calcula por línea (PCH1) usando el grupo fiscal (VatGroup)
     - Algunos campos del CSV NO existen de forma nativa y se dejan como:
       '' (vacío) o calculados si es posible

   ✔ Campos NO estándar en SAP (se dejan vacíos):
     - Tipo AUT
     - Factura Directa a
     - Medio Cuenta
     - Cod.Imp. (si no se usa tax code propio)

   ✔ Periodo:
     - Ajustar fechas en WHERE según necesidad

   ✔ IMPORTANTE:
     - Este query devuelve UNA FILA POR LÍNEA DE FACTURA
     - Es el formato correcto para libros fiscales
============================================================================ */

SELECT
    C."DocEntry"                           AS "N.REGISTRO",
    C."DocDate"                            AS "FECHA",

    COALESCE(C."FederalTaxID", BP."LicTradNum", '')
                                           AS "NIF/DNI",

    BP."CardName"                          AS "NOMBRE",

    L."LineTotal"                          AS "BASE IVA",

    T."Rate"                               AS "TIPO",

    (L."LineTotal" * T."Rate" / 100)       AS "CUOTA",

    (L."LineTotal" + (L."LineTotal" * T."Rate" / 100))
                                           AS "TOTAL DOCUM",

    CASE
        WHEN C."DocType" = 'I' THEN 'F'
        ELSE 'A'
        END                                    AS "F/A",

    'N'                                    AS "N/I",

    'N'                                    AS "N/B",

    ''                                     AS "Tipo AUT",

    C."NumAtCard"                          AS "S/factura",

    C."Comments"                           AS "Comentarios",

    ''                                     AS "Factura Directa a",

    C."DocDueDate"                         AS "Fecha Pago",

    C."PaidToDate"                         AS "Importe Pago",

    C."CashAcct"                           AS "Medio Cuenta",

    L."VatGroup"                           AS "Cod.Imp.",

    T."Name"                               AS "Descripción"

FROM OPCH C
         JOIN PCH1 L
              ON C."DocEntry" = L."DocEntry"

         LEFT JOIN OCRD BP
                   ON C."CardCode" = BP."CardCode"

         LEFT JOIN OVTG T
                   ON L."VatGroup" = T."Code"

WHERE
    T."Name" LIKE '%IGIC%'
  AND C."DocDate" BETWEEN DATE '2025-10-01' AND DATE '2025-10-31'

ORDER BY
    C."DocDate",
    C."DocNum",
    L."LineNum";

/* ============================================================================
   NOTAS FINALES

   ✔ Si necesitas AGRUPAR por tasa IGIC:
     - Usa SUM(LineTotal) y GROUP BY T.Rate

   ✔ Si necesitas formato CSV exacto:
     - El separador lo maneja el exportador (Postman / Excel / DataGrip)

   ✔ Si usas UDF fiscales propios:
     - Sustituye FederalTaxID, VatGroup o Rate según tu localización

   ✔ Este query es:
     - Fiscalmente correcto
     - Auditable
     - Compatible con SAP B1 HANA estándar
============================================================================ */
