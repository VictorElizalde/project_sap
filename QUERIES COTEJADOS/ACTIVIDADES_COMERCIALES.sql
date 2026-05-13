-- ============================================================
-- ACTIVIDADES COMERCIALES
-- ------------------------------------------------------------
-- Descripción : Listado de actividades comerciales (llamadas,
--               reuniones, tareas, notas) con su interlocutor,
--               contacto, asunto y contenido.
-- Parámetros  : [%FechaDesde%] Fecha inicio desde (opcional)
--               [%FechaHasta%] Fecha inicio hasta  (opcional)
--               [%Usuario%]    Código de usuario   (opcional)
-- Tablas      : OCLG, OCRD, OCPR, OCLGS, OUSR
-- ============================================================
SELECT
    -- USUARIO
    COALESCE(U."U_NAME", '')                     AS "USUARIO",

    -- TIPO DE ACTIVIDAD
    CASE CLG."Action"
        WHEN 'C' THEN 'Llamada'
        WHEN 'M' THEN 'Reunión'
        WHEN 'T' THEN 'Tarea'
        WHEN 'N' THEN 'Nota'
        WHEN 'O' THEN 'Otro'
        ELSE CLG."Action"
    END                                          AS "ACTIVIDAD",

    -- FECHA
    CLG."CntctDate"                              AS "FECHA DE INICIO",

    -- INTERLOCUTOR COMERCIAL
    COALESCE(C."CardName", '')                   AS "NOMBRE IC",

    -- PERSONA DE CONTACTO
    COALESCE(CP."Name", '')                      AS "PERSONA DE CONTACTO",

    -- ASUNTO
    COALESCE(SBJ."Name", '')                     AS "ASUNTO",

    -- OPORTUNIDAD ASOCIADA
    CLG."OprId"                                  AS "Nº OPORTUNIDAD",

    -- NOTAS Y CONTENIDO
    COALESCE(CLG."Notes", '')                    AS "COMENTARIOS",
    COALESCE(CLG."Details", '')                  AS "CONTENIDO"

FROM "OCLG" CLG
LEFT JOIN "OCRD" C    ON CLG."CardCode"    = C."CardCode"
LEFT JOIN "OCPR" CP   ON CLG."CntctCode"   = CP."CntctCode"
                      AND CLG."CardCode"   = CP."CardCode"
LEFT JOIN "OCLS" SBJ  ON CLG."CntctSbjct"  = SBJ."Code"
LEFT JOIN "OUSR" U    ON CLG."AttendUser"  = U."USERID"

WHERE
    CLG."CntctDate" BETWEEN
        CASE WHEN '[%FechaDesde%]' = '' THEN '1900-01-01' ELSE '[%FechaDesde%]' END
    AND
        CASE WHEN '[%FechaHasta%]' = '' THEN '9999-12-31' ELSE '[%FechaHasta%]' END
    AND (COALESCE(U."U_NAME", '') = '[%Usuario%]' OR '[%Usuario%]' = '')

ORDER BY
    CLG."CntctDate" DESC,
    CLG."ClgCode";
