-- Cifras de control del mart: granularidad, unicidad y que el JOIN no infle.
WITH unido AS (
  SELECT f.cargo_fijo, m.cod_dane
  FROM mart.fct_tarifas AS f
  LEFT JOIN mart.dim_municipio AS m USING (municipio)
)
SELECT '01 filas en el staging' AS control, COUNT(*) AS valor FROM staging.stg_tarifas
UNION ALL SELECT '02 filas en el hecho', COUNT(*) FROM mart.fct_tarifas
UNION ALL SELECT '03 llaves repetidas en el hecho',
  COUNT(*) - COUNT(DISTINCT FORMAT('%t', (municipio, sector, estrato_original, servicio, anio, mes_num)))
  FROM mart.fct_tarifas
UNION ALL SELECT '04 llaves con cargos en conflicto', COUNTIF(cargos_en_conflicto) FROM mart.fct_tarifas
UNION ALL SELECT '05 filas en dim_municipio', COUNT(*) FROM mart.dim_municipio
UNION ALL SELECT '06 municipios repetidos en la dimension', COUNT(*) - COUNT(DISTINCT municipio) FROM mart.dim_municipio
UNION ALL SELECT '07 municipios sin codigo DANE', COUNTIF(cod_dane IS NULL) FROM mart.dim_municipio
UNION ALL SELECT '08 filas despues del JOIN con dim_municipio', COUNT(*) FROM unido
UNION ALL SELECT '09 cargo fijo total antes del JOIN', CAST(ROUND(SUM(cargo_fijo)) AS INT64) FROM mart.fct_tarifas
UNION ALL SELECT '10 cargo fijo total despues del JOIN', CAST(ROUND(SUM(cargo_fijo)) AS INT64) FROM unido
UNION ALL SELECT '11 meses del calendario sin tarifas', COUNT(*)
  FROM mart.dim_periodo WHERE periodo NOT IN (SELECT periodo FROM mart.fct_tarifas)
ORDER BY control;
