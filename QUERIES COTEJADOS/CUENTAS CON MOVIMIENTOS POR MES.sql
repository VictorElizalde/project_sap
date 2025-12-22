/* =============================================================================
   INFORME: CUENTAS CON MOVIMIENTOS POR MES (FORMATO CSV)
   BASE: SAP Business One sobre HANA

   - Concepto        : Cuenta contable (código + nombre)
   - Meses           : Movimiento mensual (Debit - Credit)
   - ACUMULADO       : Total anual
   - MEDIA           : Promedio mensual (ACUMULADO / 12)

   CONSIDERACIONES IMPORTANTES:
   1) El rango de fechas define el ejercicio completo.
   2) Si una cuenta no tiene movimientos en un mes, el valor será 0.
   3) MEDIA se calcula sobre 12 meses (ajústalo si necesitas media real).
   4) Este query es apto para exportar directamente a CSV.
   5) Usa DATE nativo de HANA (no funciones MONTH() en WHERE).
   ============================================================================ */

SELECT
    A."AcctCode" || ' ' || A."AcctName" AS "Concepto",

    /* ===================== ACUMULADO ===================== */
    SUM(J."Debit" - J."Credit") AS "ACUMULADO",

    /* ======================= MEDIA ======================= */
    ROUND(SUM(J."Debit" - J."Credit") / 12, 2) AS "MEDIA",

    /* ======================= MESES ======================= */
    SUM(CASE WHEN MONTH(T."RefDate") = 1  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "ENERO",
    SUM(CASE WHEN MONTH(T."RefDate") = 2  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "FEBRERO",
    SUM(CASE WHEN MONTH(T."RefDate") = 3  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "MARZO",
    SUM(CASE WHEN MONTH(T."RefDate") = 4  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "ABRIL",
    SUM(CASE WHEN MONTH(T."RefDate") = 5  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "MAYO",
    SUM(CASE WHEN MONTH(T."RefDate") = 6  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "JUNIO",
    SUM(CASE WHEN MONTH(T."RefDate") = 7  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "JULIO",
    SUM(CASE WHEN MONTH(T."RefDate") = 8  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "AGOSTO",
    SUM(CASE WHEN MONTH(T."RefDate") = 9  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "SETIEMBRE",
    SUM(CASE WHEN MONTH(T."RefDate") = 10 THEN (J."Debit" - J."Credit") ELSE 0 END) AS "OCTUBRE",
    SUM(CASE WHEN MONTH(T."RefDate") = 11 THEN (J."Debit" - J."Credit") ELSE 0 END) AS "NOVIEMBRE",
    SUM(CASE WHEN MONTH(T."RefDate") = 12 THEN (J."Debit" - J."Credit") ELSE 0 END) AS "DICIEMBRE"

FROM "OJDT"  T
         JOIN "JDT1"  J ON T."TransId" = J."TransId"
         JOIN "OACT"  A ON J."Account" = A."AcctCode"

WHERE
    T."RefDate" >= DATE '2025-01-01'
  AND T."RefDate" <  DATE '2026-01-01'

GROUP BY
    A."AcctCode",
    A."AcctName"

ORDER BY
    A."AcctCode";

/* =============================================================================
   NOTAS FINALES:
   - Para otro ejercicio: cambia las fechas del WHERE.
   - Si quieres MEDIA dinámica (solo meses con datos), se puede ajustar.
   - Compatible con:
       ✔ Query Manager
       ✔ DataGrip
       ✔ Service Layer (vía vista)
       ✔ Exportación CSV / Excel
   ============================================================================= */
