SELECT
 A."AcctCode" || ' ' || A."AcctName" AS "Concepto",

 SUM(J."Debit" - J."Credit") AS "ACUMULADO",

 ROUND(SUM(J."Debit" - J."Credit") / 12, 2) AS "MEDIA",

 SUM(CASE WHEN MONTH(J."RefDate") = 1  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "ENERO",
 SUM(CASE WHEN MONTH(J."RefDate") = 2  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "FEBRERO",
 SUM(CASE WHEN MONTH(J."RefDate") = 3  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "MARZO",
 SUM(CASE WHEN MONTH(J."RefDate") = 4  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "ABRIL",
 SUM(CASE WHEN MONTH(J."RefDate") = 5  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "MAYO",
 SUM(CASE WHEN MONTH(J."RefDate") = 6  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "JUNIO",
 SUM(CASE WHEN MONTH(J."RefDate") = 7  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "JULIO",
 SUM(CASE WHEN MONTH(J."RefDate") = 8  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "AGOSTO",
 SUM(CASE WHEN MONTH(J."RefDate") = 9  THEN (J."Debit" - J."Credit") ELSE 0 END) AS "SETIEMBRE",
 SUM(CASE WHEN MONTH(J."RefDate") = 10 THEN (J."Debit" - J."Credit") ELSE 0 END) AS "OCTUBRE",
 SUM(CASE WHEN MONTH(J."RefDate") = 11 THEN (J."Debit" - J."Credit") ELSE 0 END) AS "NOVIEMBRE",
 SUM(CASE WHEN MONTH(J."RefDate") = 12 THEN (J."Debit" - J."Credit") ELSE 0 END) AS "DICIEMBRE"

FROM "JDT1" J
INNER JOIN "OACT" A ON J."Account" = A."AcctCode"

WHERE
  J."RefDate" >= TO_DATE(YEAR('[%0]') || '-01-01', 'YYYY-MM-DD')
  AND J."RefDate" <  ADD_YEARS(TO_DATE(YEAR('[%0]') || '-01-01', 'YYYY-MM-DD'), 1)

GROUP BY
 A."AcctCode",
 A."AcctName"

ORDER BY
 A."AcctCode";