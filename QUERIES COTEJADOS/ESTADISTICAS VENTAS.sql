/* =============================================================================
   ESTADÍSTICAS DE VENTAS – FORMATO CSV LOGÍSTICA / MARGEN
   - Basado en facturas de clientes (OINV / INV1)
   - Incluye datos comerciales, artículo, familia, marca, costes y margen
   - Algunas columnas dependen de UDFs (ver notas finales)
============================================================================= */

SELECT
    C."CardCode"                                AS "Cliente",
    C."CardName"                                AS "Nombre Cliente",
    COALESCE(V."Address2", V."Address")         AS "DIRECCION ENTREGA DE CLIENTE",

    C."GroupCode"                               AS "Cl.Agrup",
    CG."GroupName"                              AS "Ramo",
    C."IndustryC"                               AS "Actividad",

    M."FirmName"                                AS "Marca",
    G."ItmsGrpNam"                              AS "Familia",
    I."U_SubFamilia"                            AS "Subfamilia",     -- UDF habitual

    L."WhsCode"                                 AS "Depósito",
    L."ItemCode"                                AS "Articulo",
    L."Dscription"                              AS "Descripción",

    S."SlpName"                                 AS "Agente",
    V."DocNum"                                  AS "Factura",
    TO_VARCHAR(V."DocDate",'DD/MM/YYYY')        AS "Fecha",

    L."Quantity"                                AS "Cantidad",
    L."LineTotal"                               AS "Importe Venta",

    COALESCE(L."StockValue",0)                  AS "Importe Coste",
    (L."LineTotal" - COALESCE(L."StockValue",0)) AS "Importe Margen",

    CASE
        WHEN L."LineTotal" <> 0
            THEN ROUND(
                (L."LineTotal" - COALESCE(L."StockValue",0))
                    / L."LineTotal" * 100, 2)
        ELSE 0
        END                                         AS "% Margen",

    SH."TrnspName"                              AS "Forma de envio",

    ''                                          AS "Mot.Abono",       -- no estándar
    ''                                          AS "Desc. Abono",     -- no estándar

    P."CardName"                                AS "Proveedor",
    I."SuppCatNum"                              AS "Ref.Proveedor"

FROM "OINV" V
         JOIN "INV1" L   ON V."DocEntry" = L."DocEntry"
         JOIN "OCRD" C   ON V."CardCode" = C."CardCode"
         LEFT JOIN "OCRG" CG ON C."GroupCode" = CG."GroupCode"
         LEFT JOIN "OITM" I  ON L."ItemCode" = I."ItemCode"
         LEFT JOIN "OITB" G  ON I."ItmsGrpCod" = G."ItmsGrpCod"
         LEFT JOIN "OMRC" M  ON I."FirmCode" = M."FirmCode"
         LEFT JOIN "OSLP" S  ON V."SlpCode" = S."SlpCode"
         LEFT JOIN "OSHP" SH ON V."TrnspCode" = SH."TrnspCode"
         LEFT JOIN "OCRD" P  ON I."CardCode" = P."CardCode"

WHERE V."DocDate" BETWEEN DATE '2025-10-01' AND DATE '2025-10-31'
ORDER BY V."DocDate", V."DocNum", L."LineNum";

/* =============================================================================
   NOTAS IMPORTANTES
   1) Subfamilia suele ser un UDF en OITM (ej: U_SubFamilia)
   2) Mot.Abono / Desc.Abono solo existen si hay NC o UDFs
   3) Importe Coste usa INV1.StockValue (coste real SAP)
   4) % Margen se calcula a nivel línea (como en Excel)
   5) Forma de envío viene de OSHP (Transportes)
   6) Ref.Proveedor = código proveedor del artículo
============================================================================= */
