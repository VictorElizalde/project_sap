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
CASE A."FinanseAct"
WHEN 'INC' THEN '1. Importe neto de la cifra de negocios'
WHEN 'COS' THEN '4. Aprovisionamientos'
WHEN 'OEX' THEN '7. Otros gastos de explotación'
WHEN 'SAL' THEN '6. Gastos de personal'
WHEN 'FIN' THEN '13. Gastos financieros'
ELSE 'OTROS'
END AS "Concepto",

/* ===================== AÑO 2025 ===================== */
SUM(
CASE
WHEN YEAR(J."RefDate") = 2025
THEN COALESCE(J."Debit",0) - COALESCE(J."Credit",0)
ELSE 0
END
) AS "2025",

/* ===================== AÑO 2024 ===================== */
SUM(
CASE
WHEN YEAR(J."RefDate") = 2024
THEN COALESCE(J."Debit",0) - COALESCE(J."Credit",0)
ELSE 0
END
) AS "2024",

/* ===================== AÑO 2023 ===================== */
SUM(
CASE
WHEN YEAR(J."RefDate") = 2023
THEN COALESCE(J."Debit",0) - COALESCE(J."Credit",0)
ELSE 0
END
) AS "2023",

/* ===================== AÑO 2022 ===================== */
SUM(
CASE
WHEN YEAR(J."RefDate") = 2022
THEN COALESCE(J."Debit",0) - COALESCE(J."Credit",0)
ELSE 0
END
) AS "2022",

/* ===================== AÑO 2021 ===================== */
SUM(
CASE
WHEN YEAR(J."RefDate") = 2021
THEN COALESCE(J."Debit",0) - COALESCE(J."Credit",0)
ELSE 0
END
) AS "2021"

FROM "OACT" A
LEFT JOIN "JDT1" J
ON J."Account" = A."AcctCode"
AND YEAR(J."RefDate") BETWEEN 2021 AND 2025

WHERE
A."FinanseAct" IS NOT NULL

GROUP BY
A."FinanseAct"

ORDER BY
A."FinanseAct";

/* =============================================================================
 NOTAS FINALES:
 - Para subtotales A, B, C, D (Resultado explotación, financiero, etc.)
 se recomienda:
 a) Ejecutar este query como base
 b) Agrupar en Excel / Power BI / Crystal Reports
 - SAP estándar también calcula subtotales fuera del SQL.
 - Si deseas subtotales en SQL, se puede hacer con UNION ALL.
 ============================================================================= */
