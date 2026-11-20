-- Cifras de control del staging: filas antes y después, y nulos nuevos.
SELECT '1 filas en el bruto' AS control, COUNT(*) AS valor FROM bruto.nfrm_mmfe
UNION ALL SELECT '2 filas en el staging', COUNT(*) FROM staging.stg_tarifas
UNION ALL SELECT '3 municipios en el bruto', COUNT(DISTINCT municipio) FROM bruto.nfrm_mmfe
UNION ALL SELECT '4 municipios en el staging', COUNT(DISTINCT municipio) FROM staging.stg_tarifas
UNION ALL SELECT '5 mes sin convertir', COUNTIF(mes_num IS NULL) FROM staging.stg_tarifas
UNION ALL SELECT '6 cargo fijo sin convertir', COUNTIF(cargo_fijo IS NULL) FROM staging.stg_tarifas
UNION ALL SELECT '7 estrato nulo (no residencial)', COUNTIF(estrato_num IS NULL) FROM staging.stg_tarifas
UNION ALL SELECT '8 estrato nulo en residencial', COUNTIF(estrato_num IS NULL AND sector = 'Residencial') FROM staging.stg_tarifas
ORDER BY control;
