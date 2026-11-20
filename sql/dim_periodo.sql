-- Dimensión periodo: una fila por mes, del primero al último que tiene el hecho.
CREATE OR REPLACE TABLE mart.dim_periodo AS
SELECT
  periodo,
  EXTRACT(YEAR FROM periodo) AS anio,
  EXTRACT(MONTH FROM periodo) AS mes_num,
  EXTRACT(QUARTER FROM periodo) AS trimestre,
  FORMAT_DATE('%Y-%m', periodo) AS anio_mes
FROM UNNEST(GENERATE_DATE_ARRAY(
  (SELECT MIN(periodo) FROM mart.fct_tarifas),
  (SELECT MAX(periodo) FROM mart.fct_tarifas),
  INTERVAL 1 MONTH)) AS periodo;
