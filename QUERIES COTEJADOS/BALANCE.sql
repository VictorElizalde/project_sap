-- ============================================================
-- BALANCE
-- ------------------------------------------------------------
-- Descripción : Balance de situación. Devuelve cargos, abonos
--               y saldo por cuenta contable para el ejercicio
--               indicado. Filtra cuentas de Activo (1), Pasivo
--               (2) y Patrimonio Neto (3).
-- Parámetros  : [%Ejercicio%] Año contable (YYYY)
-- Tablas      : JDT1, OACT
-- ============================================================
SELECT
    A."AcctCode"        AS "Cuenta",
    A."AcctName"        AS "Nombre Cuenta",
    A."GroupMask"       AS "Grupo Cuenta",
    CASE A."GroupMask"
        WHEN 1 THEN 'ACTIVO'
        WHEN 2 THEN 'PASIVO'
        WHEN 3 THEN 'PATRIMONIO NETO'
        WHEN 4 THEN 'INGRESOS'
        WHEN 5 THEN 'GASTOS'
        ELSE 'OTROS'
    END                 AS "Tipo Cuenta",
    SUM(J."Debit")      AS "Cargos",
    SUM(J."Credit")     AS "Abonos",
    SUM(J."Debit" - J."Credit") AS "Saldo",
    YEAR(J."RefDate")   AS "Ejercicio"
FROM "JDT1" J
INNER JOIN "OACT" A ON J."Account" = A."AcctCode"
WHERE
    J."RefDate" >= TO_DATE('[%Ejercicio%]' || '-01-01', 'YYYY-MM-DD')
    AND J."RefDate" <  ADD_YEARS(TO_DATE('[%Ejercicio%]' || '-01-01', 'YYYY-MM-DD'), 1)
    AND A."GroupMask" IN (1, 2, 3)
GROUP BY
    A."AcctCode",
    A."AcctName",
    A."GroupMask",
    YEAR(J."RefDate")
ORDER BY
    A."GroupMask",
    A."AcctCode";
