/* =============================================================================
 QUERY: DEUDA PROVEEDORES – CSV EXPORT
 SISTEMA: SAP Business One sobre HANA

 OBJETIVO:
 - Generar un CSV de deuda pendiente de proveedores
 - Una fila por factura abierta
 - Cobertura máxima de campos estándar SAP B1
 ============================================================================= */

SELECT
 P."CardCode" AS "Proveedor",
 P."CardName" AS "Nombre",

 TO_VARCHAR(F."DocDueDate", 'DD/MM/YYYY') AS "Vto",
 F."DocNum" AS "Documento",

CASE F."ObjType"
WHEN '18' THEN 'Factura Proveedor'
WHEN '19' THEN 'Nota Crédito Proveedor'
ELSE 'Documento'
END AS "Tipo Doc.",

 TO_VARCHAR(F."DocDate", 'DD/MM/YYYY') AS "Fecha",

COALESCE(F."NumAtCard", '') AS "S/Factura",

 F."DocStatus" AS "Est.",

 F."DocEntry" AS "Id.",

COALESCE(F."PeyMethod", '') AS "T.P.",

COALESCE(P."BankCode", '') AS "Banco",

COALESCE(P."SWIFT", '') AS "C.I.G.",

 (F."DocTotal" - F."PaidToDate") AS "Importe",

CASE
WHEN COALESCE(F."DocTotalFC", 0) <> 0
THEN (F."DocTotalFC" - F."PaidFC")
ELSE 0
END AS "Importe Div.",

 F."DocCur" AS "DIV"

FROM "OPCH" F
INNER JOIN "OCRD" P
ON F."CardCode" = P."CardCode"

WHERE
 F."Canceled" = 'N'                         -- Excluir cancelados
AND F."DocTotal" > F."PaidToDate"           -- Con saldo pendiente
AND (
 '[%0]' = '' 
 OR F."DocDate" <= TO_DATE('[%0]', 'DD/MM/YYYY')
 )

ORDER BY
 P."CardName",
 F."DocDueDate";

/* =============================================================================
 NOTAS Y CONSIDERACIONES IMPORTANTES
 -----------------------------------------------------------------------------
 1. Devuelve SOLO facturas de proveedor con saldo pendiente.
 2. No desglosa pagos parciales (una fila por factura).
 3. "Importe Div." se calcula SOLO si existe importe en moneda extranjera.
 4. Banco y C.I.G. dependen del maestro de proveedores (OCRD).
 5. Tipos de documento estándar:
    - 18 = Factura proveedor
    - 19 = Nota crédito proveedor
 6. Parámetro:
    [%0] = Fecha corte (opcional, DD/MM/YYYY)
 7. Compatible con:
    ✔ Query Manager
    ✔ DataGrip
    ✔ Exportación directa a CSV
 ============================================================================= */
