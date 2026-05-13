-- ============================================================
-- SUMAS Y SALDOS
-- ------------------------------------------------------------
-- Descripción : Balance de sumas y saldos. Devuelve saldo de
--               apertura, cargos/abonos del período,
--               acumulados históricos y saldo final por cuenta
--               para el ejercicio indicado.
-- Parámetros  : [%Ejercicio%] Año contable (YYYY)
-- Tablas      : OACT, JDT1, OJDT
-- ============================================================
SELECT
    A."AcctCode"                              AS "Cuenta",
    A."AcctName"                              AS "Nombre Cuenta",

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
    SUM(J."Debit" - J."Credit")               AS "Saldo"

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
