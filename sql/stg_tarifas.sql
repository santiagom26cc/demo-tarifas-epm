-- Staging de tarifas de EPM (demo del curso)
-- Origen: bruto.nfrm_mmfe, cargado tal como llegó de la API (todo es texto).
-- Una fila del staging = una fila del bruto: aquí no se quita ninguna.
-- T1 Tipos: año, mes, estrato y cargos pasan de texto a número.
-- T2 Catálogo: «Estrella» es el mismo municipio que «La Estrella».
CREATE OR REPLACE VIEW staging.stg_tarifas AS
SELECT
  socrata_id AS id_fila,
  CASE TRIM(municipio) WHEN 'Estrella' THEN 'La Estrella' ELSE TRIM(municipio) END AS municipio,
  sector,
  servicio,
  estrato AS estrato_original,
  SAFE_CAST(estrato AS INT64) AS estrato_num,
  SAFE_CAST(year AS INT64) AS anio,
  CASE LOWER(TRIM(mes))
    WHEN 'enero' THEN 1 WHEN 'febrero' THEN 2 WHEN 'marzo' THEN 3
    WHEN 'abril' THEN 4 WHEN 'mayo' THEN 5 WHEN 'junio' THEN 6
    WHEN 'julio' THEN 7 WHEN 'agosto' THEN 8 WHEN 'septiembre' THEN 9
    WHEN 'octubre' THEN 10 WHEN 'noviembre' THEN 11 WHEN 'diciembre' THEN 12
  END AS mes_num,
  SAFE_CAST(cargofijo AS NUMERIC) AS cargo_fijo,
  SAFE_CAST(cargoporconsumo AS NUMERIC) AS cargo_consumo,
  SAFE_CAST(cargoporconsumomenor AS NUMERIC) AS cargo_consumo_menor,
  SAFE_CAST(cargoporconsumomayor AS NUMERIC) AS cargo_consumo_mayor,
  archivo_origen
FROM bruto.nfrm_mmfe;
