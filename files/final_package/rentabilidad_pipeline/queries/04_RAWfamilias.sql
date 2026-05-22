-- ============================================================
-- QUERY 4: RAWfamilias (Family → Canal mapping)
-- Replaces: RAWfamilias sheet in Stock.xlsx
-- Loads into Power BI as table: RAW_Familias
-- Schedule: Static — refresh monthly or on demand
--           (this rarely changes)
--
-- This is the master lookup table that assigns each product
-- family to its commercial canal: CONSUMO, HOTEL, PROFESIONAL,
-- or PROMOCIONAL. Used as a dimension table in the Power BI
-- data model, joined to RAWstock and RAWalbaranes on Familia.
-- ============================================================

SELECT
    ITB."ItmsGrpCod"                                               AS "CodFamilia",
    ITB."ItmsGrpNam"                                               AS "Familia",

    -- Canal mapping (exact match to RAWfamilias Excel sheet)
    CASE ITB."ItmsGrpNam"
        -- CONSUMO
        WHEN 'MANDOS'                   THEN 'CONSUMO'
        WHEN 'TELEVISORES'              THEN 'CONSUMO'
        WHEN 'ZONA OUTLET'              THEN 'CONSUMO'

        -- HOTEL
        WHEN 'TV ACCESORIOS'            THEN 'HOTEL'
        WHEN 'HOTEL TV'                 THEN 'HOTEL'
        WHEN 'VARIOS'                   THEN 'HOTEL'

        -- PROFESIONAL
        WHEN 'SOPORTES'                 THEN 'PROFESIONAL'
        WHEN 'ACCESORIOS'               THEN 'PROFESIONAL'
        WHEN 'AV'                       THEN 'PROFESIONAL'
        WHEN 'CABLES'                   THEN 'PROFESIONAL'
        WHEN 'LED'                      THEN 'PROFESIONAL'
        WHEN 'MONITORES'                THEN 'PROFESIONAL'
        WHEN 'PLAYERS'                  THEN 'PROFESIONAL'
        WHEN 'PROCESADOR PANTALLAS LED' THEN 'PROFESIONAL'
        WHEN 'PROYECCION'               THEN 'PROFESIONAL'
        WHEN 'TACTILES'                 THEN 'PROFESIONAL'
        WHEN 'TOTEMS'                   THEN 'PROFESIONAL'
        WHEN 'VIDEOWALL'                THEN 'PROFESIONAL'
        WHEN 'INFORMATICA'              THEN 'PROFESIONAL'

        -- PROMOCIONAL
        WHEN 'AUDIO PROFESIONAL'        THEN 'PROMOCIONAL'
        WHEN 'BALANCE SCOOTER'          THEN 'PROMOCIONAL'
        WHEN 'CAMARAS'                  THEN 'PROMOCIONAL'
        WHEN 'DRONES'                   THEN 'PROMOCIONAL'
        WHEN 'GAMA BLANCA'              THEN 'PROMOCIONAL'
        WHEN 'MALETAS / MOCHILAS'       THEN 'PROMOCIONAL'
        WHEN 'MOVILES'                  THEN 'PROMOCIONAL'
        WHEN 'OCIO'                     THEN 'PROMOCIONAL'
        WHEN 'PAE'                      THEN 'PROMOCIONAL'
        WHEN 'PATINETES'                THEN 'PROMOCIONAL'
        WHEN 'RELOJ'                    THEN 'PROMOCIONAL'
        WHEN 'TABLETS'                  THEN 'PROMOCIONAL'
        WHEN 'TELEFONIA FIJA'           THEN 'PROMOCIONAL'
        WHEN 'VEHICULOS ELECTRICOS'     THEN 'PROMOCIONAL'
        WHEN 'VIDEOCONSOLAS'            THEN 'PROMOCIONAL'
        WHEN 'WEARABLES'                THEN 'PROMOCIONAL'
        WHEN 'CAJAS FUERTE'             THEN 'PROMOCIONAL'

        ELSE 'OTROS'
    END                                                             AS "Canal",

    -- Optional: flag families that are grouped as "conjunto" in Excel
    CASE ITB."ItmsGrpNam"
        WHEN 'SOPORTES'    THEN 'Conjunto'
        WHEN 'ACCESORIOS'  THEN 'Conjunto'
        WHEN 'CABLES'      THEN 'Conjunto'
        ELSE NULL
    END                                                             AS "Agrupacion",

    -- Notes matching the Excel comments
    CASE ITB."ItmsGrpNam"
        WHEN 'TV ACCESORIOS' THEN 'Adaptador no tiene canal asignado'
        ELSE NULL
    END                                                             AS "Nota"

FROM  OITB  ITB

WHERE  ITB."ItmsGrpNam" IN (
    'MANDOS', 'TELEVISORES', 'ZONA OUTLET',
    'TV ACCESORIOS', 'HOTEL TV', 'VARIOS',
    'SOPORTES', 'ACCESORIOS', 'AV', 'CABLES', 'LED',
    'MONITORES', 'PLAYERS', 'PROCESADOR PANTALLAS LED',
    'PROYECCION', 'TACTILES', 'TOTEMS', 'VIDEOWALL', 'INFORMATICA',
    'AUDIO PROFESIONAL', 'BALANCE SCOOTER', 'CAMARAS', 'DRONES',
    'GAMA BLANCA', 'MALETAS / MOCHILAS', 'MOVILES', 'OCIO',
    'PAE', 'PATINETES', 'RELOJ', 'TABLETS', 'TELEFONIA FIJA',
    'VEHICULOS ELECTRICOS', 'VIDEOCONSOLAS', 'WEARABLES', 'CAJAS FUERTE'
)

ORDER BY
    "Canal",
    "Familia"
;
