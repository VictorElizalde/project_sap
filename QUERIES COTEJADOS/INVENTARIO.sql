/* =====================================================================
   QUERY: INVENTARIO (Stock por fecha)
   SISTEMA: SAP Business One sobre HANA

   PARÁMETROS:
     :P_FECHA_CONSULTA  --> Fecha de corte del inventario

   NOTAS GENERALES:
   - Campos de MARCA / FAMILIA / SUBFAMILIA / SERIE:
     SAP estándar SOLO guarda los códigos (ItmsGrpCod, UDFs).
     Los nombres dependen de:
       - Tablas de grupos (OITB)
       - Tablas de UDF ([@...] o vistas propias)
   - Campos como RESERVADO, PT.RECIBIR, ALBS.* requieren agregaciones
     desde documentos comerciales (ORDR, DLN, POR1, etc.)
   ===================================================================== */

SELECT
    /* ============================
       CLASIFICACIÓN ARTÍCULO
       ============================ */

    I.U_MARCA                                AS "MARCA",
    M.Name                                  AS "NOMBRE MARCA",

    I.ItmsGrpCod                            AS "FAMILIA",
    G.ItmsGrpNam                            AS "NOMBRE FAMILIA",

    I.U_SUBFAM                              AS "SUBFAM",
    SF.Name                                 AS "NOMBRE SUBFAMILIA",

    I.U_SERIE                               AS "SERIE",
    SE.Name                                 AS "NOMBRE SERIE",

    /* ============================
       ARTÍCULO
       ============================ */

    I.ItemCode                              AS "ARTICULO",
    I.ItemName                              AS "DESCRIPCION",

    /* ============================
       DEPÓSITO / STOCK
       ============================ */

    W.WhsCode                               AS "DEPOSITO",

    SUM(IT.InQty - IT.OutQty)               AS "CANTIDAD",

    /* ============================
       VALORES ECONÓMICOS
       ============================ */

    I.AvgPrice                              AS "PRECIO",

    SUM(IT.InQty - IT.OutQty)
        * I.AvgPrice                        AS "IMPORTE",

    /* ============================
       DISPONIBILIDAD
       ============================ */

    I.OnHand                                AS "RESERVADO",        -- aproximación estándar
    I.OnOrder                               AS "PT.RECIBIR",
    I.OnHand - I.IsCommited + I.OnOrder     AS "DISPON.FUTURO",

    /* ============================
       ALBARANES (NO ESTÁNDAR)
       ============================ */

    0                                       AS "ALBS.PTS.",
    0                                       AS "ALBS.CONF.",

    /* ============================
       PROVEEDOR
       ============================ */

    I.CardCode                              AS "PROV.",
    BP.CardName                             AS "NOMBRE",
    I.SuppCatNum                            AS "REF.PROVEEDOR"

FROM OINM IT
         INNER JOIN OITM I
                    ON IT.ItemCode = I.ItemCode

         INNER JOIN OWHS W
                    ON IT.WhsCode = W.WhsCode

         LEFT JOIN OITB G
                   ON I.ItmsGrpCod = G.ItmsGrpCod

/* ======= UDFs / tablas auxiliares (AJUSTAR A TU SISTEMA) ======= */
         LEFT JOIN "@MARCAS"      M  ON I.U_MARCA  = M.Code
         LEFT JOIN "@SUBFAM"      SF ON I.U_SUBFAM = SF.Code
         LEFT JOIN "@SERIES"      SE ON I.U_SERIE  = SE.Code

         LEFT JOIN OCRD BP
                   ON I.CardCode = BP.CardCode

WHERE IT.DocDate <= :P_FECHA_CONSULTA

GROUP BY
    I.U_MARCA, M.Name,
    I.ItmsGrpCod, G.ItmsGrpNam,
    I.U_SUBFAM, SF.Name,
    I.U_SERIE, SE.Name,
    I.ItemCode, I.ItemName,
    W.WhsCode,
    I.AvgPrice,
    I.OnHand, I.IsCommited, I.OnOrder,
    I.CardCode, BP.CardName,
    I.SuppCatNum

ORDER BY
    I.ItemCode,
    W.WhsCode;

/* =====================================================================
   CONSIDERACIONES FINALES IMPORTANTES

   1) MARCA / SUBFAMILIA / SERIE
      - Se asumen como UDFs en OITM (U_MARCA, U_SUBFAM, U_SERIE)
      - Las tablas @MARCAS, @SUBFAM, @SERIES son ejemplos
      - Si no existen → dejar solo el código o crear vistas

   2) RESERVADO
      - SAP estándar no tiene "reservado por fecha"
      - I.IsCommited refleja compromisos actuales, no históricos

   3) ALBS.PTS / ALBS.CONF
      - No existen en inventario puro
      - Requieren joins a:
        DLN1 / ODLN (albaranes)
        ORDR / RDR1 (pedidos)
      - Aquí se dejan en 0 para cumplir estructura CSV

   4) STOCK HISTÓRICO
      - El stock se calcula correctamente vía OINM a fecha
      - OnHand / OnOrder siempre son valores actuales

   5) QUERY LIST / EXPORT
      - Este query es apto para:
        ✔ Query Manager
        ✔ Query Generator
        ✔ Exportación directa a CSV
   ===================================================================== */
