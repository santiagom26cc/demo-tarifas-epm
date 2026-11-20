-- Dimensión municipio: una fila por municipio de EPM, con su código DANE.
-- Clave: municipio (el nombre de EPM, ya unificado en el staging).
-- M1 Se compara por nombre sin tildes y en mayúsculas (nombre_clave).
-- M2 Dos nombres de EPM cambian en DIVIPOLA: El Retiro es RETIRO y Belén de Bajirá es NUEVO BELÉN DE BAJIRÁ.
-- M3 Barbosa, Caldas y Rionegro existen en dos departamentos: se toma el de Antioquia (05).
-- M4 El Reposo no está en DIVIPOLA: queda sin código, declarado en el README.
CREATE OR REPLACE TABLE mart.dim_municipio AS
WITH municipios_epm AS (
  SELECT DISTINCT
    municipio,
    CASE municipio
      WHEN 'El Retiro' THEN 'RETIRO'
      WHEN 'Belén de Bajirá' THEN 'NUEVO BELEN DE BAJIRA'
      ELSE UPPER(REGEXP_REPLACE(NORMALIZE(municipio, NFD), r'\p{M}', ''))
    END AS nombre_clave
  FROM staging.stg_tarifas
),
catalogo AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY nombre_clave ORDER BY IF(cod_dpto = '05', 0, 1), cod_mpio) AS opcion
  FROM staging.stg_divipola
)
SELECT
  e.municipio,
  c.cod_mpio AS cod_dane,
  c.municipio_dane,
  c.departamento
FROM municipios_epm AS e
LEFT JOIN catalogo AS c
  ON c.nombre_clave = e.nombre_clave AND c.opcion = 1;
