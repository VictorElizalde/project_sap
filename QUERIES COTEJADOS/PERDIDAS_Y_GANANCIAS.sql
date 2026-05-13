-- ============================================================
-- PÉRDIDAS Y GANANCIAS
-- ------------------------------------------------------------
-- Descripción : Cuenta de pérdidas y ganancias multianual.
--               Agrupa cuentas de ingresos y gastos en
--               epígrafes contables para el ejercicio indicado
--               y los 4 años anteriores (GroupMask 4 y 5).
-- Parámetros  : [%Ejercicio%] Año de referencia (YYYY)
-- Tablas      : OJDT, JDT1, OACT
-- ============================================================
SELECT
    CASE
        WHEN A."AcctCode" BETWEEN '70000000' AND '79999999'
            THEN '1. Importe neto de la cifra de negocios'
        WHEN A."AcctCode" BETWEEN '60000000' AND '60999999'
            THEN '4. Aprovisionamientos'
        WHEN A."AcctCode" BETWEEN '62000000' AND '62999999'
            THEN '6. Gastos de personal'
        WHEN A."AcctCode" BETWEEN '63000000' AND '63999999'
            THEN '7. Otros gastos de explotación'
        WHEN A."AcctCode" BETWEEN '66000000' AND '66999999'
            THEN '13. Gastos financieros'
        ELSE 'OTROS'
    END AS "Concepto",

    /* ===================== 2025 ===================== */
    SUM(
        CASE
            WHEN YEAR(T."RefDate") = 2025
            THEN (J."Debit" - J."Credit")
            ELSE 0
        END
    ) AS "2025",

    /* ===================== 2024 ===================== */
    SUM(
        CASE
            WHEN YEAR(T."RefDate") = 2024
            THEN (J."Debit" - J."Credit")
            ELSE 0
        END
    ) AS "2024",

    /* ===================== 2023 ===================== */
    SUM(
        CASE
            WHEN YEAR(T."RefDate") = 2023
            THEN (J."Debit" - J."Credit")
            ELSE 0
        END
    ) AS "2023",

    /* ===================== 2022 ===================== */
    SUM(
        CASE
            WHEN YEAR(T."RefDate") = 2022
            THEN (J."Debit" - J."Credit")
            ELSE 0
        END
    ) AS "2022",

    /* ===================== 2021 ===================== */
    SUM(
        CASE
            WHEN YEAR(T."RefDate") = 2021
            THEN (J."Debit" - J."Credit")
            ELSE 0
        END
    ) AS "2021"

FROM "OJDT" T
JOIN "JDT1" J
  ON T."TransId" = J."TransId"
JOIN "OACT" A
  ON J."Account" = A."AcctCode"

WHERE
    YEAR(T."RefDate") BETWEEN 2021 AND 2025
AND A."GroupMask" = 4        -- 🔑 SOLO CUENTAS DE PÉRDIDAS Y GANANCIAS

GROUP BY
    CASE
        WHEN A."AcctCode" BETWEEN '70000000' AND '79999999'
            THEN '1. Importe neto de la cifra de negocios'
        WHEN A."AcctCode" BETWEEN '60000000' AND '60999999'
            THEN '4. Aprovisionamientos'
        WHEN A."AcctCode" BETWEEN '62000000' AND '62999999'
            THEN '6. Gastos de personal'
        WHEN A."AcctCode" BETWEEN '63000000' AND '63999999'
            THEN '7. Otros gastos de explotación'
        WHEN A."AcctCode" BETWEEN '66000000' AND '66999999'
            THEN '13. Gastos financieros'
        ELSE 'OTROS'
    END

ORDER BY
    "Concepto";
