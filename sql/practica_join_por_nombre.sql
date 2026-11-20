-- Práctica: las 12 tarifas del indicador, unidas con DIVIPOLA solo por el nombre.
-- Entran 12 filas. ¿Cuántas salen y por qué?
WITH tarifa AS (
  SELECT municipio, cargo_fijo
  FROM mart.fct_tarifas
  WHERE servicio = 'Acueducto' AND sector = 'Residencial' AND estrato_num = 3
    AND periodo = '2026-10-01' AND NOT cargos_en_conflicto
)
SELECT t.municipio, d.cod_mpio, d.departamento, t.cargo_fijo
FROM tarifa AS t
JOIN staging.stg_divipola AS d
  ON d.nombre_clave = UPPER(REGEXP_REPLACE(NORMALIZE(t.municipio, NFD), r'\p{M}', ''))
ORDER BY t.municipio, d.cod_mpio;
