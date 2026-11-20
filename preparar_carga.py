#!/usr/bin/env python3
"""Prepara el bruto de data/raw para cargarlo a BigQuery, sin cambiar ningún dato.

Uso (en la carpeta de tu repositorio, después de una corrida completa de extraer.py):
    python3 preparar_carga.py                 usa el bruto más reciente de data/raw
    python3 preparar_carga.py data/raw/X.json usa ese archivo

Qué hace:
  1. Comprueba que el bruto salió de una corrida completa anotada en conteos.csv
     y que tiene las mismas filas que esa corrida (la cifra de control).
  2. Lo escribe como JSON de una fila por línea, que es lo que pide BigQuery:
     data/bq/<conjunto>.ndjson
  3. Escribe el esquema con TODAS las columnas como texto (STRING):
     data/bq/<conjunto>_esquema.json
     El bruto se carga tal como llegó; los tipos se deciden en el staging.
  4. Te muestra los comandos de bq para cargar y contar.

Cambios de forma (no de contenido), para que BigQuery acepte los nombres:
  :id -> socrata_id · :created_at -> socrata_creado · :updated_at -> socrata_actualizado
  :version -> socrata_version · otros caracteres raros en un nombre -> _
  Se agrega la columna archivo_origen con el nombre del bruto (linaje).

Solo usa la biblioteca estándar de Python: no hay nada que instalar.
"""
import csv
import glob
import json
import os
import re
import sys

SISTEMA = {":id": "socrata_id", ":created_at": "socrata_creado",
           ":updated_at": "socrata_actualizado", ":version": "socrata_version"}


def miles(n):
    return f"{n:,}".replace(",", ".")


def nombre_columna(clave):
    if clave in SISTEMA:
        return SISTEMA[clave]
    n = re.sub(r"[^0-9a-zA-Z_]", "_", clave.strip()).lower()
    if not n or n[0].isdigit():
        n = "c_" + n
    return n


def corrida_de(archivo):
    """La fila de conteos.csv que guardó este bruto (estado completa)."""
    if not os.path.exists("conteos.csv"):
        return None
    with open("conteos.csv", encoding="utf-8") as f:
        filas = [r for r in csv.DictReader(f) if r.get("estado") == "completa"]
    destino = os.path.normpath(archivo)
    for r in reversed(filas):
        if r.get("archivo") and os.path.normpath(r["archivo"]) == destino:
            return r
    return None


def main():
    if len(sys.argv) > 1:
        archivo = sys.argv[1]
    else:
        brutos = sorted(glob.glob(os.path.join("data", "raw", "*.json")), key=os.path.getmtime)
        if not brutos:
            sys.exit("ALTO: no hay brutos en data/raw. Primero corre extraer.py hasta tener una corrida completa.")
        archivo = brutos[-1]
    if not os.path.exists(archivo):
        sys.exit(f"ALTO: no existe {archivo}")

    with open(archivo, encoding="utf-8") as f:
        filas = json.load(f)
    if not isinstance(filas, list):
        sys.exit("ALTO: el bruto no es una lista de filas. ¿Salió de extraer.py?")

    base = os.path.basename(archivo)
    conjunto = re.sub(r"_\d{4}-\d{2}-\d{2}_\d{6}\.json$", "", base).replace(".json", "")
    tabla = re.sub(r"[^0-9a-zA-Z_]", "_", conjunto).lower()
    print(f"Bruto: {archivo}")
    print(f"Filas en el bruto: {miles(len(filas))}")

    # 1. Cifra de control contra conteos.csv
    corrida = corrida_de(archivo)
    if corrida is None:
        print("OJO: no encontré en conteos.csv una corrida completa que guardara este archivo.")
        print("     Sin esa fila no hay cifra de control. Vuelve a correr extraer.py.")
        sys.exit(1)
    traidas = int(corrida["traidas"])
    if traidas != len(filas):
        sys.exit(f"ALTO: conteos.csv dice {miles(traidas)} traídas y el bruto tiene {miles(len(filas))}. No cargues.")
    print(f"conteos.csv ({corrida['fecha']}): esperadas {miles(int(corrida['esperadas']))} · "
          f"traídas {miles(traidas)} -> cuadra con el bruto")

    # 2 y 3. Una fila por línea y esquema en texto
    columnas = []
    vistas = set()
    os.makedirs(os.path.join("data", "bq"), exist_ok=True)
    salida = os.path.join("data", "bq", f"{conjunto}.ndjson")
    with open(salida, "w", encoding="utf-8") as out:
        for r in filas:
            fila = {}
            for k, v in r.items():
                n = nombre_columna(k)
                if n not in vistas:
                    vistas.add(n)
                    columnas.append(n)
                if v is None:
                    continue
                fila[n] = v if isinstance(v, str) else json.dumps(v, ensure_ascii=False)
            fila["archivo_origen"] = base
            out.write(json.dumps(fila, ensure_ascii=False) + "\n")
    columnas.append("archivo_origen")
    repetidas = [c for c in set(columnas) if columnas.count(c) > 1]
    if repetidas:
        sys.exit(f"ALTO: dos columnas quedan con el mismo nombre: {repetidas}. Avísale al profe.")
    esquema = os.path.join("data", "bq", f"{conjunto}_esquema.json")
    with open(esquema, "w", encoding="utf-8") as f:
        json.dump([{"name": c, "type": "STRING", "mode": "NULLABLE"} for c in columnas], f, indent=1)

    print(f"Listo: {salida} ({miles(len(filas))} líneas, {len(columnas)} columnas, todas texto)")
    print()
    print("Ahora, en esta misma carpeta (la primera línea solo la primera vez):")
    print("  bq mk --dataset --location=US bruto")
    print(f"  bq load --replace --source_format=NEWLINE_DELIMITED_JSON bruto.{tabla} {salida} {esquema}")
    print(f"  bq query --use_legacy_sql=false 'SELECT COUNT(*) AS filas FROM bruto.{tabla}'")
    print()
    print(f"Cifra de control: el COUNT(*) tiene que dar {miles(len(filas))}.")


if __name__ == "__main__":
    main()
