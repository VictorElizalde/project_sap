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
    SUM(CASE WHEN YEAR(T."RefDate") = TO_INTEGER('[%Ejercicio%]')     THEN (J."Debit" - J."Credit") ELSE 0 END) AS "Año N",
    SUM(CASE WHEN YEAR(T."RefDate") = TO_INTEGER('[%Ejercicio%]') - 1 THEN (J."Debit" - J."Credit") ELSE 0 END) AS "Año N-1",
    SUM(CASE WHEN YEAR(T."RefDate") = TO_INTEGER('[%Ejercicio%]') - 2 THEN (J."Debit" - J."Credit") ELSE 0 END) AS "Año N-2",
    SUM(CASE WHEN YEAR(T."RefDate") = TO_INTEGER('[%Ejercicio%]') - 3 THEN (J."Debit" - J."Credit") ELSE 0 END) AS "Año N-3",
    SUM(CASE WHEN YEAR(T."RefDate") = TO_INTEGER('[%Ejercicio%]') - 4 THEN (J."Debit" - J."Credit") ELSE 0 END) AS "Año N-4"
FROM "OJDT" T
JOIN "JDT1" J ON T."TransId" = J."TransId"
JOIN "OACT" A ON J."Account" = A."AcctCode"
WHERE
    YEAR(T."RefDate") BETWEEN TO_INTEGER('[%Ejercicio%]') - 4 AND TO_INTEGER('[%Ejercicio%]')
    AND A."GroupMask" IN (4, 5)
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
