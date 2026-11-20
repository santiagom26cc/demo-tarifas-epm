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
