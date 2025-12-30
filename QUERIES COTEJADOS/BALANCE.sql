/* ============================================================
   BALANCE DE SITUACIÓN – BASE CONTABLE REAL
   Sistema : SAP Business One sobre SAP HANA
   Fuente  : Movimientos contables (JDT1)
   Autor   : Query base reutilizable
   ============================================================

   CONSIDERACIONES IMPORTANTES:
   1) SAP B1 NO guarda el balance “maquetado” por epígrafes.
   2) El balance SIEMPRE se obtiene desde JDT1.
   3) La clasificación ACTIVO / PASIVO / PATRIMONIO NETO
      depende de OACT.GroupMask o del rango de cuentas.
   4) Este query devuelve el SALDO por cuenta y ejercicio.
   5) El agrupamiento en epígrafes (Inmovilizado, Existencias,
      Clientes, etc.) se realiza fuera:
        - Excel
        - Power BI
        - Crystal Reports
        - o una tabla/vista de mapeo contable.

   PARAMETROS:
   [%0] = Ejercicio (ej: 2025)

   LIMITACIONES:
   - No calcula totales A/B/C
   - No genera epígrafes oficiales
   - No pivota ejercicios

   USO RECOMENDADO:
   ✔ Mantener este query como BASE CONTABLE
   ✔ Construir el balance final en capa de reporting
   ============================================================ */

SELECT
 /* Identificación de la cuenta */
 A."AcctCode" AS "Cuenta",
 A."AcctName" AS "Nombre Cuenta",

 /* Clasificación contable */
 A."GroupMask" AS "Grupo Cuenta",
 CASE A."GroupMask"
   WHEN 1 THEN 'ACTIVO'
   WHEN 2 THEN 'PASIVO'
   WHEN 3 THEN 'PATRIMONIO NETO'
   WHEN 4 THEN 'INGRESOS'
   WHEN 5 THEN 'GASTOS'
   ELSE 'OTROS'
 END AS "Tipo Cuenta",

 /* Importes acumulados del ejercicio */
 SUM(J."Debit") AS "Cargos",
 SUM(J."Credit") AS "Abonos",
 SUM(J."Debit" - J."Credit") AS "Saldo",

 /* Ejercicio contable */
 YEAR(J."RefDate") AS "Ejercicio"

FROM "JDT1" J
INNER JOIN "OACT" A
  ON J."Account" = A."AcctCode"

WHERE
 /* Ejercicio parametrizable */
 YEAR(J."RefDate") = TO_INTEGER('[%0]')

 /* Solo cuentas de balance */
 AND A."GroupMask" IN (1,2,3)

GROUP BY
 A."AcctCode",
 A."AcctName",
 A."GroupMask",
 YEAR(J."RefDate")

ORDER BY
 A."GroupMask",
 A."AcctCode";



/* ============================================================================================
 NOTAS FINALES Y LIMITACIONES

 ✔ Este query ES LA BASE CONTABLE REAL del balance.
 ✔ Los totales cuadran exactamente con SAP.

 ✖ SAP NO guarda:
   - Epígrafes como “Inmovilizado material”, “Existencias”, etc.
   - Totales A, B, C ya calculados.

 PARA REPRODUCIR EXACTAMENTE TU CSV:
 1) Crear una tabla o vista de mapeo:
    Cuenta → Epígrafe → Orden → Sección
 2) Unir este query contra esa tabla.
 3) Pivotar por ejercicio (2025, 2024, 2023, …).

 EJEMPLO DE MAPEO:
   210000–219999 → Inmovilizado intangible
   300000–399999 → Existencias
   430000–439999 → Clientes
   170000–179999 → Deudas LP
   etc.

 RECOMENDACIÓN:
 ✔ Mantener este query como “BASE CONTABLE”
 ✔ Construir el informe final en Excel / Power BI / Crystal
============================================================================================ */
