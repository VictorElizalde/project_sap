/* =============================================================================
 INFORME: PÉRDIDAS Y GANANCIAS (PyG) MULTIANUAL – FORMATO CSV
 BASE: SAP Business One sobre SAP HANA
 -----------------------------------------------------------------------------
 CONSIDERACIONES IMPORTANTES:
 1) El PyG se construye a partir de OACT.FinanseAct (clasificación contable).
 2) Los importes se calculan como: Debit - Credit.
 3) Las cuentas sin movimiento aparecen con 0.
 4) Los textos de "Concepto" pueden ajustarse a tu formato oficial.
 5) Los años se controlan por RefDate (asiento contable).
 6) Este query replica la lógica del informe estándar de PyG de SAP.
 ============================================================================= */

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

/* =============================================================================
 NOTAS FINALES:
 - Para subtotales A, B, C, D (Resultado explotación, financiero, etc.)
 se recomienda:
 a) Ejecutar este query como base
 b) Agrupar en Excel / Power BI / Crystal Reports
 - SAP estándar también calcula subtotales fuera del SQL.
 - Si deseas subtotales en SQL, se puede hacer con UNION ALL.
 ============================================================================= */
