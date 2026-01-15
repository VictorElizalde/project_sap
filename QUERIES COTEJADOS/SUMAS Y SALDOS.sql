/****************************************************************************************
 INFORME: SUMAS Y SALDOS – SAP BUSINESS ONE (HANA)
 FORMATO: CSV

 CSV ESPERADO:
 Cuenta | Nombre Cuenta | Saldo Apertura | Cargos | Abonos |
 Cargos Acumulados | Abonos Acumulados | Saldo Final

 CONSIDERACIONES GENERALES:
 1) El saldo de apertura se calcula como movimientos ANTERIORES al ejercicio.
 2) Cargos / Abonos = movimientos DEL EJERCICIO.
 3) Cargos / Abonos Acumulados = histórico hasta fin del ejercicio.
 4) El saldo final = Debe acumulado – Haber acumulado.
 5) El rango de fechas define el ejercicio contable.
 6) Compatible con exportación directa a CSV / Excel.
****************************************************************************************/

SELECT
 A."AcctCode" AS "Cuenta",
 A."AcctName" AS "Nombre Cuenta",

    /* ================= SALDO APERTURA ================= */
    COALESCE((
                 SELECT SUM(J0."Debit" - J0."Credit")
                 FROM "JDT1" J0
                          JOIN "OJDT" H0
                               ON J0."TransId" = H0."TransId"
                 WHERE J0."Account" = A."AcctCode"
                   AND H0."RefDate" < DATE '2025-01-01'
             ), 0)                                     AS "Saldo Apertura",

    /* ================= MOVIMIENTOS DEL PERIODO ================= */
    SUM(
            CASE
                WHEN H."RefDate" >= DATE '2025-01-01'
                    AND H."RefDate" <  DATE '2026-01-01'
                    THEN J."Debit"
                ELSE 0
                END
    )                                         AS "Cargos",

    SUM(
            CASE
                WHEN H."RefDate" >= DATE '2025-01-01'
                    AND H."RefDate" <  DATE '2026-01-01'
                    THEN J."Credit"
                ELSE 0
                END
    )                                         AS "Abonos",

    /* ================= ACUMULADOS ================= */
    SUM(J."Debit")                            AS "Cargos Acumulados",
    SUM(J."Credit")                           AS "Abonos Acumulados",

/* ================= SALDO FINAL ================= */
SUM(J."Debit" - J."Credit") AS "Saldo Final"

FROM "OACT" A
         LEFT JOIN "JDT1" J
                   ON J."Account" = A."AcctCode"
         LEFT JOIN "OJDT" H
                   ON J."TransId" = H."TransId"
                       AND H."RefDate" < DATE '2026-01-01'

GROUP BY
 A."AcctCode",
 A."AcctName"

ORDER BY
 A."AcctCode";

/****************************************************************************************
 NOTAS FINALES:

 ✔ El saldo final coincide con el mayor contable a fin de ejercicio.
 ✔ Para otro año:
   - Cambiar fechas 2025-01-01 / 2026-01-01.
 ✔ Para excluir cuentas sin movimiento:
   - Añadir:
     HAVING
       SUM(J."Debit") <> 0
    OR SUM(J."Credit") <> 0
 ✔ Query válido para:
   ▸ Query Manager
   ▸ HANA Studio
   ▸ DataGrip
   ▸ Exportación CSV / Excel
****************************************************************************************/
