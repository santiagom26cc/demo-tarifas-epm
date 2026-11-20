-- La trampa: unir el hecho con DIVIPOLA solo por el nombre del municipio.
-- Corre sin error. Compara estas cifras con las del hecho (controles 02 y 09).
SELECT
  COUNT(*) AS filas,
  COUNT(DISTINCT f.municipio) AS municipios,
  CAST(ROUND(SUM(f.cargo_fijo)) AS INT64) AS cargo_fijo_total
FROM mart.fct_tarifas AS f
JOIN staging.stg_divipola AS d
  ON d.nombre_clave = UPPER(REGEXP_REPLACE(NORMALIZE(f.municipio, NFD), r'\p{M}', ''));
