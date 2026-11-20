-- Indicador: cargo fijo de acueducto, residencial estrato 3, octubre de 2026, por municipio.
-- Paso 1 (CTE): las tarifas que entran. Paso 2: se les pone el código DANE.
WITH tarifa AS (
  SELECT municipio, cargo_fijo
  FROM mart.fct_tarifas
  WHERE servicio = 'Acueducto' AND sector = 'Residencial' AND estrato_num = 3
    AND periodo = '2026-10-01' AND NOT cargos_en_conflicto
)
SELECT m.cod_dane, t.municipio, t.cargo_fijo
FROM tarifa AS t
JOIN mart.dim_municipio AS m USING (municipio)
ORDER BY t.cargo_fijo DESC, t.municipio;
