-- Staging del catálogo DIVIPOLA del DANE (gdxc-w37w).
-- Origen: bruto.gdxc_w37w, cargado tal como llegó (todo texto).
-- Una fila = un municipio, isla o área no municipalizada; cod_mpio no se repite.
-- D1 nombre_clave: el nombre sin tildes y en mayúsculas, para comparar con otras fuentes.
-- D2 Coordenadas: llegan con coma decimal ("-75,581775"); se cambia por punto antes de convertir.
CREATE OR REPLACE VIEW staging.stg_divipola AS
SELECT
  cod_mpio,
  cod_dpto,
  dpto AS departamento,
  nom_mpio AS municipio_dane,
  UPPER(REGEXP_REPLACE(NORMALIZE(nom_mpio, NFD), r'\p{M}', '')) AS nombre_clave,
  tipo_municipio,
  SAFE_CAST(REPLACE(longitud, ',', '.') AS NUMERIC) AS longitud,
  SAFE_CAST(REPLACE(latitud, ',', '.') AS NUMERIC) AS latitud,
  archivo_origen
FROM bruto.gdxc_w37w;
