-- Hecho tarifas. Granularidad: una fila = el cargo de un servicio para un municipio,
-- un sector y un estrato en un mes.
-- Llave natural: municipio, sector, estrato_original, servicio, anio, mes_num.
-- H1 Copias: el staging trae 24.611 filas para 24.005 llaves. Se deja una por llave (ROW_NUMBER).
-- H2 Conflicto: en algunas llaves las copias traen cargos distintos y ningún campo dice cuál es
--    la buena. Se marcan (cargos_en_conflicto) y los indicadores las excluyen, declarado.
CREATE OR REPLACE TABLE mart.fct_tarifas AS
WITH numeradas AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY municipio, sector, estrato_original, servicio, anio, mes_num
      ORDER BY id_fila) AS n_copia,
    COUNT(*) OVER (
      PARTITION BY municipio, sector, estrato_original, servicio, anio, mes_num) AS filas_llave,
    COUNT(*) OVER (
      PARTITION BY municipio, sector, estrato_original, servicio, anio, mes_num,
                   cargo_fijo, cargo_consumo, cargo_consumo_menor, cargo_consumo_mayor) AS filas_iguales
  FROM staging.stg_tarifas
)
SELECT
  municipio,
  sector,
  estrato_original,
  estrato_num,
  servicio,
  anio,
  mes_num,
  DATE(anio, mes_num, 1) AS periodo,
  cargo_fijo,
  cargo_consumo,
  cargo_consumo_menor,
  cargo_consumo_mayor,
  filas_llave AS filas_en_staging,
  filas_iguales < filas_llave AS cargos_en_conflicto,
  id_fila,
  archivo_origen
FROM numeradas
WHERE n_copia = 1;
