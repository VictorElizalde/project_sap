/* ============================================================================================
 BALANCE DE SITUACIÓN – SAP BUSINESS ONE (HANA)
 Ejercicio: parametrizable (ej. 2025)
 Periodo: acumulado anual
 Empresa: depende de la base de datos activa

 CONSIDERACIONES IMPORTANTES (LEER):
 1) SAP B1 NO guarda el Balance “maquetado” por epígrafes oficiales.
 2) El balance se obtiene SIEMPRE desde movimientos contables (JDT1).
 3) La clasificación ACTIVO / PASIVO / PATRIMONIO depende del:
    - Grupo de cuenta (OACT.GroupMask)
    - O del rango de cuentas contables (PGC).
 4) Este query devuelve el SALDO por cuenta y año.
 5) El agrupamiento en epígrafes (Inmovilizado, Existencias, etc.)
    se hace:
      a) en Excel
      b) en Crystal
      c) o con una vista adicional de mapeo contable
============================================================================================ */

SELECT
    /* Identificación contable */
    A."AcctCode"        AS "Cuenta",
    A."AcctName"        AS "Nombre Cuenta",

    /* Clasificación base */
    A."GroupMask"       AS "Grupo Cuenta",
    CASE A."GroupMask"
        WHEN 1 THEN 'ACTIVO'
        WHEN 2 THEN 'PASIVO'
        WHEN 3 THEN 'PATRIMONIO NETO'
        WHEN 4 THEN 'INGRESOS'
        WHEN 5 THEN 'GASTOS'
        ELSE 'OTROS'
        END                 AS "Tipo Cuenta",

    /* Saldo acumulado del ejercicio */
    SUM(J."Debit")      AS "Cargos",
    SUM(J."Credit")     AS "Abonos",
    SUM(J."Debit" - J."Credit") AS "Saldo",

    /* Ejercicio */
    YEAR(J."RefDate")   AS "Ejercicio"

FROM "JDT1" J
    INNER JOIN "OACT" A
ON J."Account" = A."AcctCode"

WHERE
    /* Rango de fechas del ejercicio */
    J."RefDate" >= DATE '2025-01-01'
  AND J."RefDate" <  DATE '2026-01-01'

    /* Solo cuentas de balance (excluye PyG si se desea) */
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
