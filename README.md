# Nombre del proyecto

Equipo E__ · Análisis de Datos Intermedio · Estud-IA (Capa 2)

## Brief v1

| Campo | Respuesta |
|---|---|
| Usuario y decisión | ¿Quién decide qué, y cada cuánto? |
| Pregunta | ¿Qué quieres responder? |
| Fuente con API | Enlace al endpoint (…/resource/xxxx-xxxx.json) |
| Qué representa una fila | |
| Campo que la identifica | |
| Cada cuánto se actualiza | |
| Dato a confirmar | |
| Tres indicadores | 1. · 2. · 3. |
| Terminó bien si… | Una regla que se responde sí o no y que otra persona puede verificar |
| No vamos a construir | |

## Contrato de datos

- Una fila es:
- La identifica:
- Si llega una fila repetida:
- Si falta un campo:

## Bitácora de decisiones

| Fecha | Decisión | Por qué |
|---|---|---|
| | | |

## Reglas del repositorio

- Es público: nada de datos personales, contraseñas, tokens ni llaves.
- Las credenciales van en un archivo `.env`, que Git ignora (ver `.gitignore`). `.env.example` muestra qué variables hacen falta, sin valores.
- Cada commit explica en su mensaje qué se decidió y por qué.

## Carga y staging (S4)

### Carga a BigQuery

| | |
|---|---|
| Bruto cargado | `data/raw/nfrm-mmfe_2026-11-20_132510.json` |
| Tabla en BigQuery | `bruto.nfrm_mmfe` (todas las columnas como texto) |
| Traídas según `conteos.csv` | 24.611 |
| `COUNT(*)` en BigQuery | 24.611 |

### Staging: de dónde viene cada columna

Archivo: `sql/stg_tarifas.sql` (vista `staging.stg_tarifas`).

| Columna en el staging | Viene de (bruto) | Regla |
|---|---|---|
| `id_fila` | `socrata_id` (el `:id` de la API) | Igual |
| `municipio` | `municipio` | T2: «Estrella» pasa a «La Estrella» |
| `estrato_num` | `estrato` | T1: texto a entero; queda nulo si no es residencial |
| `anio` | `year` | T1: texto a entero |
| `mes_num` | `mes` | T1: «Enero» a 1 … «Diciembre» a 12 |
| `cargo_fijo`, `cargo_consumo` | `cargofijo`, `cargoporconsumo` | T1: texto a número |

### Conteo antes y después (`sql/controles_stg.sql`)

| Control | Bruto | Staging | ¿Es lo esperado? |
|---|---|---|---|
| Filas | 24.611 | 24.611 | Sí: el staging no quita filas |
| Municipios | 25 | 24 | Sí: T2 unió dos nombres del mismo municipio |
| Estrato nulo | — | 8.193 | Sí: son las filas no residenciales; en residencial hay 0 |
| Mes o cargo fijo sin convertir | — | 0 | Sí |

### Pendiente para la S5

24.611 filas y 24.005 combinaciones distintas de municipio, sector, estrato, servicio, año y mes: 606 filas de más (en el bruto eran 604; T2 juntó dos más en enero de 2018). En la S5 se decide qué representa una fila del hecho.

## Modelo (S5)

### Granularidad

Una fila de `mart.fct_tarifas` = el cargo de un servicio para un municipio, un sector y un estrato en un mes. Llave natural: `municipio`, `sector`, `estrato_original`, `servicio`, `anio`, `mes_num`.

### Tablas

| Tabla | Una fila es | Clave | Filas |
|---|---|---|---|
| `mart.fct_tarifas` | Una tarifa en un mes | La llave natural | 24.005 |
| `mart.dim_municipio` | Un municipio de EPM, con su código DANE | `municipio` | 24 |
| `mart.dim_periodo` | Un mes | `periodo` | 118 |

    dim_municipio (24) 1 ──< N fct_tarifas (24.005) N >── 1 dim_periodo (118)

### Reglas

| Regla | Qué decide | Cifra |
|---|---|---|
| H1 | Una fila por llave con `ROW_NUMBER()` | 24.611 filas del staging → 24.005 |
| H2 | En 234 llaves las copias traen cargos distintos y ningún campo dice cuál es la buena: `cargos_en_conflicto` y los indicadores las excluyen | 234 |
| M1–M4 | Código DANE por nombre sin tildes; El Retiro = RETIRO y Belén de Bajirá = NUEVO BELÉN DE BAJIRÁ; Barbosa, Caldas y Rionegro, los de Antioquia; El Reposo sin código | 24 municipios, 1 sin código |

### Controles (`sql/controles_mart.sql`)

| Control | Valor | ¿Es lo esperado? |
|---|---|---|
| Llaves repetidas en el hecho | 0 | Sí |
| Municipios repetidos en la dimensión | 0 | Sí: la clave de la dimensión no se repite |
| Filas antes y después del JOIN con `dim_municipio` | 24.005 = 24.005 | Sí: el JOIN no multiplica |
| Cargo fijo total antes y después del JOIN | 172.140.093 = 172.140.093 | Sí |
| Meses del calendario sin tarifas | 0 | Sí |

### La trampa que evitamos (`sql/trampa_join.sql`)

Unir con DIVIPOLA solo por el nombre corre sin error y da 28.331 filas (no 24.005) y un cargo fijo total de 203.901.533 (no 172.140.093). Barbosa, Caldas y Rionegro se duplican porque existen en dos departamentos; El Retiro, Belén de Bajirá y El Reposo desaparecen porque su nombre no cruza.

### Fuentes

- EPM `nfrm-mmfe`: 24.611 filas (corrida del 20 nov).
- DANE DIVIPOLA `gdxc-w37w`: 1.122 filas y 1.122 códigos distintos (corrida del 20 nov).
