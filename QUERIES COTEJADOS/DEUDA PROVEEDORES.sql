/* =============================================================================
   QUERY: DEUDA PROVEEDORES – CSV EXPORT
   SISTEMA: SAP Business One sobre HANA
   OBJETIVO:
   - Generar un CSV de deuda pendiente de proveedores
   - Una fila por factura abierta
   - Cobertura máxima de campos estándar SAP B1
   ============================================================================= */

SELECT
    P.CardCode                                   AS "Proveedor",
    P.CardName                                   AS "Nombre",

    TO_VARCHAR(F.DocDueDate, 'DD/MM/YYYY')       AS "Vto",
    F.DocNum                                     AS "Documento",

    CASE F.ObjType
        WHEN '18' THEN 'Factura Proveedor'
        WHEN '19' THEN 'Nota Crédito Proveedor'
        ELSE 'Documento'
        END                                          AS "Tipo Doc.",

    TO_VARCHAR(F.DocDate, 'DD/MM/YYYY')          AS "Fecha",

    COALESCE(F.NumAtCard, '')                    AS "S/Factura",

    F.DocStatus                                  AS "Est.",

    F.DocEntry                                   AS "Id.",

    COALESCE(F.PeyMethod, '')                    AS "T.P.",

    COALESCE(P.BankCode, '')                     AS "Banco",

    COALESCE(P.SWIFT, '')                        AS "C.I.G.",

    (F.DocTotal - F.PaidToDate)                  AS "Importe",

    CASE
        WHEN F.DocCur <> F.SysCurr
            THEN (F.DocTotalFC - F.PaidFC)
        ELSE 0
        END                                          AS "Importe Div.",

    F.DocCur                                     AS "DIV"

FROM OPCH F
         JOIN OCRD P
              ON F.CardCode = P.CardCode

WHERE
    F.DocTotal > F.PaidToDate              -- Solo documentos con saldo pendiente
  AND F.Canceled = 'N'                   -- Excluir cancelados
  AND F.DocDate <= :FechaConsulta        -- Parámetro de fecha

ORDER BY
    P.CardName,
    F.DocDueDate;

/* =============================================================================
   NOTAS Y CONSIDERACIONES IMPORTANTES
   -----------------------------------------------------------------------------
   1. Este query devuelve SOLO facturas de proveedor abiertas (con saldo).
   2. Si deseas incluir pagos parciales como líneas separadas → no aplica aquí.
   3. "Importe Div." solo se rellena cuando la moneda ≠ moneda del sistema.
   4. Banco y C.I.G. dependen de datos maestros del proveedor (OCRD).
   5. Tipo Doc. se identifica por ObjType estándar:
      - 18 = Factura proveedor
      - 19 = Nota crédito proveedor
   6. Compatible para:
      - Query Manager
      - Service Layer (con adaptación de parámetros)
      - Exportación directa a CSV
   ============================================================================= */
