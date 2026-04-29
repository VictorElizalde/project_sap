SELECT 
    T0."CardCode" AS "Código Cliente", 
    T0."CardName" AS "Nombre Cliente", 
    T1."Address" AS "Nombre Dirección", 
    T1."Street" AS "Calle", 
    T1."ZipCode" AS "CP", 
    T1."City" AS "Ciudad", 
    T1."State" AS "Provincia",
    T1."County" 
FROM OCRD T0 
INNER JOIN CRD1 T1 ON T0."CardCode" = T1."CardCode"
WHERE 
    T0."CardType" = 'C' 
    AND T1."AdresType" = 'S'