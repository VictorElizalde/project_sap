/****************************************************************************************
 SUMAS Y SALDOS – SAP BUSINESS ONE (HANA)

 CSV ESPERADO:
 Cuenta;Nombre Cuenta;Saldo Apertura;Cargos;Abonos;Cargos;Abonos;Saldo

 CONSIDERACIONES GENERALES:
 - El saldo de apertura se calcula como movimientos ANTERIORES al año analizado.
 - Cargos / Abonos (1ª pareja) = movimientos DEL AÑO.
 - Cargos / Abonos (2ª pareja) = movimientos ACUMULADOS (históricos).
 - El saldo final = Debe acumulado – Haber acumulado.
 - Ajusta las fechas si necesitas otro ejercicio.
****************************************************************************************/

SELECT
    A."AcctCode"                              AS "Cuenta",
    A."AcctName"                              AS "Nombre Cuenta",

    /* ================= SALDO APERTURA ================= */
    COALESCE((
                 SELECT SUM(J0."Debit" - J0."Credit")
                 FROM "JDT1" J0
                 WHERE J0."Account" = A."AcctCode"
                   AND J0."RefDate" < DATE '2025-01-01'
             ), 0)                                     AS "Saldo Apertura",

    /* ================= MOVIMIENTOS DEL AÑO ================= */
    SUM(
            CASE
                WHEN J."RefDate" >= DATE '2025-01-01'
                    AND J."RefDate" <  DATE '2026-01-01'
                    THEN J."Debit"
                ELSE 0
                END
    )                                         AS "Cargos",

    SUM(
            CASE
                WHEN J."RefDate" >= DATE '2025-01-01'
                    AND J."RefDate" <  DATE '2026-01-01'
                    THEN J."Credit"
                ELSE 0
                END
    )                                         AS "Abonos",

    /* ================= MOVIMIENTOS ACUMULADOS ================= */
    SUM(J."Debit")                            AS "Cargos Acumulados",
    SUM(J."Credit")                           AS "Abonos Acumulados",

    /* ================= SALDO FINAL ================= */
    SUM(J."Debit" - J."Credit")               AS "Saldo"

FROM "OACT" A
         LEFT JOIN "JDT1" J
                   ON J."Account" = A."AcctCode"
                       AND J."RefDate" < DATE '2026-01-01'

GROUP BY
    A."AcctCode",
    A."AcctName"

ORDER BY
    A."AcctCode";

/****************************************************************************************
 NOTAS FINALES:
 - Si deseas SUMAS Y SALDOS por rango de fechas, cambia las fechas del WHERE.
 - Si necesitas excluir cuentas sin movimiento, agrega:
       HAVING SUM(J."Debit") <> 0 OR SUM(J."Credit") <> 0
 - Compatible con exportación directa a CSV.
 - Estructura alineada 1:1 con el CSV solicitado.
****************************************************************************************/
