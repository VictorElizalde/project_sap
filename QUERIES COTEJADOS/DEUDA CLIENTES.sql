/******************************************************************************************
 CSV: DEUDA CLIENTES (Facturas abiertas)

 Columnas requeridas:
 Cliente | Nombre | Vto | Documento | Tipo Doc. | Situación | Fecha | Tem. | Agente |
 Banco | Remesa | T.Rem. | C.G. | Importe | Importe Div. | DIV |
 NIF | Cl.Agrup. | Dias Demora

 CONSIDERACIONES IMPORTANTES (LEER ANTES):
 1) Este listado es SOLO para CLIENTES → se usa OINV (facturas de clientes),
    NO OPCH (que es proveedores).
 2) SAP B1 NO maneja Remesas, T.Rem. ni Cl.Agrup. como estándar:
    → se dejan como columnas vacías.
 3) "Situación" se interpreta como:
    - 'Abierta' → DocStatus = 'O'
    - 'Cerrada' → DocStatus = 'C'
 4) "Dias Demora" se calcula contra la fecha del sistema (CURRENT_DATE).
 5) "C.G." se interpreta como Cuenta Contable de control del cliente (OCRD.DebPayAcct).
 6) Importe = Total factura - Pagado a la fecha.
******************************************************************************************/

SELECT
 I."CardCode"      AS "Cliente",
 C."CardName"      AS "Nombre",

 I."DocDueDate"    AS "Vto",
 I."DocNum"        AS "Documento",
 'Factura'         AS "Tipo Doc.",

 CASE
   WHEN I."DocStatus" = 'O' THEN 'Abierta'
   ELSE 'Cerrada'
 END               AS "Situación",

 I."DocDate"       AS "Fecha",

 C."GroupNum"      AS "Tem.",        -- Condición de pago
 I."SlpCode"       AS "Agente",

 C."BankCode"      AS "Banco",
 ''                AS "Remesa",      -- No estándar SAP
 ''                AS "T.Rem.",      -- No estándar SAP

 C."DebPayAcct"    AS "C.G.",        -- Cuenta control cliente

 ( COALESCE(I."DocTotal",0)
 - COALESCE(I."PaidToDate",0) )       AS "Importe",

 ( COALESCE(I."DocTotalFC",0)
 - COALESCE(I."PaidFC",0) )           AS "Importe Div.",

 I."DocCur"        AS "DIV",

 C."LicTradNum"    AS "NIF",

 ''                AS "Cl.Agrup.",    -- No estándar SAP

 CASE
   WHEN I."DocStatus" = 'O'
    AND I."DocDueDate" < CURRENT_DATE
   THEN DAYS_BETWEEN(I."DocDueDate", CURRENT_DATE)
   ELSE 0
 END               AS "Dias Demora"

FROM "OINV" I
INNER JOIN "OCRD" C
        ON I."CardCode" = C."CardCode"

WHERE
 I."DocStatus" = 'O'                           -- Solo facturas abiertas
AND COALESCE(I."DocTotal",0)
  > COALESCE(I."PaidToDate",0)                 -- Con saldo pendiente

ORDER BY
 I."DocDueDate",
 C."CardName";

/******************************************************************************************
 NOTAS FINALES:

 ✔ Este query genera TODAS las columnas del CSV solicitado.
 ✔ Las columnas sin correspondencia estándar en SAP se dejan explícitamente en blanco.
 ✔ Si tu sistema usa UDFs para Remesas / Agrupaciones, se pueden sustituir fácilmente.
 ✔ Compatible con SAP Business One sobre HANA (SQLScript).

 Sugerencia:
 - Ideal para:
   ▸ Crystal Reports
   ▸ DataGrip
   ▸ Consultas de Usuario
   ▸ Exportación directa a CSV
******************************************************************************************/
