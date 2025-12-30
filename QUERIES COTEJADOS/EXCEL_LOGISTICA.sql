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
 /* Pedido */
 COALESCE(o."DocNum", d."BaseRef") AS "Código Pedido",
 TO_VARCHAR(o."DocDate", 'DD/MM/YYYY') AS "Fecha Pedido",

 /* Albarán */
 d."DocNum" AS "Núm.Albarán",
 TO_VARCHAR(d."DocDate", 'DD/MM/YYYY') AS "Fecha Albarán",

 /* Expediente / referencia */
 COALESCE(d."NumAtCard",'') AS "Expediente",

 /* Cliente */
 d."CardCode" AS "Código destinatario",
 d."CardName" AS "Nombre destinatario",

 /* Dirección */
 COALESCE(d."Address2", d."Address") AS "Dirección destinatario",
 COALESCE(c."ZipCode",'') AS "C.Postal destinatario",
 COALESCE(c."City",'') AS "Población destinatario",
 COALESCE(c."State1",'') AS "Provincia destinatario",
 COALESCE(c."Country",'') AS "País destinatario",

 /* Fiscal / contacto */
 COALESCE(c."LicTradNum",'') AS "CIF destinatario",
 COALESCE(c."Phone1",'') AS "Teléfono destinatario",

 /* Observaciones */
 COALESCE(d."Comments",'') AS "Obs.destinatario",

 /* Portes */
 CASE
   WHEN UPPER(COALESCE(l."ItemCode",'')) LIKE '%PORT%'
   THEN l."LineTotal"
   ELSE NULL
 END AS "Portes",

 /* Importes */
 d."DocTotal" AS "Valor Asegurado",
 '' AS "Albarán valorado",

 /* Transporte (genérico, sin campos no estándar) */
 '' AS "Transportista",
 '' AS "Servicio transportista",

 /* Línea */
 l."LineNum" AS "Línia comanda",
 l."ItemCode" AS "Código artículo",
 l."Dscription" AS "Descripción",
 l."Quantity" AS "Cantidad",

 /* Peso (no estándar → neutro) */
 0 AS "Peso",

 /* Otros */
 COALESCE(c."E_Mail",'') AS "e-mail",
 COALESCE(o."NumAtCard",'') AS "S/Referencia Pedido",
 COALESCE(l."FreeText",'') AS "Observaciones almacen",
 d."BPLName" AS "Datos empresa"

FROM "ODLN" d
INNER JOIN "DLN1" l
  ON d."DocEntry" = l."DocEntry"

LEFT JOIN "ORDR" o
  ON o."DocEntry" = l."BaseEntry"
 AND l."BaseType" = 17

LEFT JOIN "OCRD" c
  ON d."CardCode" = c."CardCode"

WHERE
 ( '[%0]' = '' OR d."DocNum" = TO_INTEGER('[%0]') )
AND
 ( '[%1]' = '' OR d."CardCode" = '[%1]' )
AND
 ( '[%2]' = '' OR d."DocDate" >= TO_DATE('[%2]', 'DD/MM/YYYY') )

ORDER BY
 d."DocNum",
 l."LineNum";


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