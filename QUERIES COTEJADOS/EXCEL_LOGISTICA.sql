/* =========================================================================================
   CONSULTA: EXCEL LOGÍSTICA (Vivace) – Máxima cobertura posible
   SISTEMA: SAP Business One sobre SAP HANA

   Código Pedido;
   Fecha Pedido;
   Núm.Albarán;
   Fecha Albarán;
   Expediente;
   Código destinatario;
   Nombre destinatario;
   Dirección destinatario;
   C.Postal destinatario;
   Población destinatario;
   Provincia destinatario;
   País destinatario;
   CIF destinatario;
   Teléfono destinatario;
   Obs.destinatario;
   Portes;
   Valor Asegurado;
   Albarán valorado;
   Transportista;
   Servicio transportista;
   Línia comanda;
   Código artículo;
   Descripción;
   Cantidad;
   Peso;
   e-mail;
   S/Referencia Pedido;
   Observaciones externas;
   Observaciones almacen;
   Datos empresa

   ENFOQUE:
   - Documento base: ODLN (Delivery Notes / Albaranes)
   - Líneas: DLN1
   - Pedido origen (si existe): ORDR
   - Maestro de clientes: OCRD
   - Dirección / impuestos: AddressExtension + TaxExtension (cuando exista)

   ========================================================================================= */

SELECT
    /* ===================== PEDIDO ===================== */
    COALESCE(o.Reference1, d.Reference1, TO_VARCHAR(o.DocNum))
        AS "Código Pedido",

    TO_VARCHAR(o.DocDate, 'DD/MM/YYYY')
        AS "Fecha Pedido",

    /* ===================== ALBARÁN ===================== */
    TO_VARCHAR(d.DocNum)
        AS "Núm.Albarán",

    TO_VARCHAR(d.DocDate, 'DD/MM/YYYY')
        AS "Fecha Albarán",

    COALESCE(d.Reference2, '')
        AS "Expediente",

    /* ===================== DESTINATARIO ===================== */
    d.CardCode
        AS "Código destinatario",

    d.CardName
        AS "Nombre destinatario",

    COALESCE(d.Address2, d.Address, o.Address)
        AS "Dirección destinatario",

    COALESCE(
            d.ShipToZipCode,
            c.ZipCode,
            ''
    )
        AS "C.Postal destinatario",

    COALESCE(
            d.ShipToCity,
            c.City,
            ''
    )
        AS "Población destinatario",

    COALESCE(
            d.ShipToState,
            c.State1,
            ''
    )
        AS "Provincia destinatario",

    COALESCE(
            d.ShipToCountry,
            c.Country,
            ''
    )
        AS "País destinatario",

    COALESCE(
            d.FederalTaxID,
            o.FederalTaxID,
            c.FederalTaxID,
            ''
    )
        AS "CIF destinatario",

    COALESCE(
            d.Phone1,
            o.Phone1,
            c.Phone1,
            ''
    )
        AS "Teléfono destinatario",

    COALESCE(d.Comments, o.Comments, '')
        AS "Obs.destinatario",

    /* ===================== LOGÍSTICA ===================== */
    CASE
        WHEN UPPER(COALESCE(l.ItemCode, '')) LIKE '%PORT%'
            THEN COALESCE(l.LineTotal, 0)
        ELSE NULL
        END
        AS "Portes",

    COALESCE(d.DocTotal, 0)
        AS "Valor Asegurado",

    ''
        AS "Albarán valorado",

    COALESCE(d.TransportationCode, '')
        AS "Transportista",

    ''
        AS "Servicio transportista",

    /* ===================== LÍNEAS ===================== */
    l.LineNum
        AS "Línia comanda",

    l.ItemCode
        AS "Código artículo",

    COALESCE(l.ItemDescription, l.Dscription)
        AS "Descripción",

    TO_DECIMAL(l.Quantity, 19, 6)
        AS "Cantidad",

    COALESCE(l.Weight1, l.Weight2, 0)
        AS "Peso",

    /* ===================== CONTACTO ===================== */
    COALESCE(c.E_Mail, '')
        AS "e-mail",

    COALESCE(o.NumAtCard, d.NumAtCard, '')
        AS "S/Referencia Pedido",

    /* ===================== OBSERVACIONES ===================== */
    COALESCE(d.Comments, o.Comments, '')
        AS "Observaciones externas",

    COALESCE(l.FreeText, '')
        AS "Observaciones almacen",

    COALESCE(d.BPLName, o.BPLName, '')
        AS "Datos empresa"

FROM ODLN d
         INNER JOIN DLN1 l
                    ON d.DocEntry = l.DocEntry

/* Pedido origen (cuando el albarán proviene de pedido) */
         LEFT JOIN ORDR o
                   ON o.DocNum = d.Reference1

/* Maestro de clientes */
         LEFT JOIN OCRD c
                   ON d.CardCode = c.CardCode

/* ===================== FILTROS ===================== */
/* Ejemplo por número de albarán */
-- WHERE d.DocNum = :P_NUMALBARAN

/* Ejemplo por estado */
-- AND d.DocumentStatus = 'bost_Open'

ORDER BY
    d.DocNum,
    l.LineNum;

/* =========================================================================================
   CONSIDERACIONES IMPORTANTES:

   1. SAP B1 NO permite JOIN directo entre documentos vía Service Layer.
      Este query es para:
      - Query Manager
      - Vista HANA
      - DataGrip / JDBC
      - Exportación a CSV

   2. Algunos campos (Transportista, Servicio, Albarán valorado)
      NO existen de forma estándar en SAP B1:
      → Se dejan vacíos o se deben mapear a UDFs si existen.

   3. Dirección, CP, Ciudad, Provincia y País:
      - Se prioriza ShipTo del documento
      - Fallback al maestro OCRD

   4. Portes:
      - Se detectan por ItemCode que contenga 'PORT'
      - Ajustar lógica según catálogo real

   5. Un registro del CSV = 1 línea de albarán
      (comportamiento correcto para Excel logístico)

   6. Formato de fechas y separadores:
      - Fechas DD/MM/YYYY
      - Listo para exportar con ';' como separador

   7. Para Service Layer:
      - NO es viable este JOIN
      - Debe hacerse en backend (Node / Python / SQL)

   ========================================================================================= */
