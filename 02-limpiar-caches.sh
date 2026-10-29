#!/usr/bin/env bash
# 02-limpiar-caches.sh
# Busca y elimina carpetas pesadas regenerables: node_modules, __pycache__,
# .pytest_cache, .mypy_cache, .ruff_cache, .next, .parcel-cache, .turbo.
# Por seguridad, el modo por defecto es dry-run (solo lista y suma tamaños).
set -euo pipefail

DIR="."
EJECUTAR=0
DIAS=0
NOMBRES=(node_modules __pycache__ .pytest_cache .mypy_cache .ruff_cache .next .parcel-cache .turbo)

uso() {
  cat <<'AYUDA'
Uso: 02-limpiar-caches.sh [opciones] [DIRECTORIO]

Encuentra carpetas de dependencias y cachés regenerables y muestra cuánto
espacio ocupan. Solo borra si pasas --ejecutar.

Opciones:
  -n, --dry-run        Solo listar (comportamiento por defecto).
  -x, --ejecutar       Borrar de verdad (pide escribir 'si' para confirmar).
  -d, --dias N         Solo carpetas sin modificar en los últimos N días.
  -h, --help           Muestra esta ayuda.

Carpetas buscadas: node_modules __pycache__ .pytest_cache .mypy_cache
                   .ruff_cache .next .parcel-cache .turbo

Ejemplos:
  02-limpiar-caches.sh ~/proyectos
  02-limpiar-caches.sh --dias 30 --ejecutar ~/proyectos
AYUDA
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) EJECUTAR=0 ;;
    -x|--ejecutar) EJECUTAR=1 ;;
    -d|--dias) DIAS="${2:?Falta N}"; shift ;;
    -h|--help) uso; exit 0 ;;
    -*) echo "Opción desconocida: $1" >&2; exit 1 ;;
    *) DIR="$1" ;;
  esac
  shift
done

[[ -d "$DIR" ]] || { echo "No existe el directorio: $DIR" >&2; exit 1; }
[[ "$DIAS" =~ ^[0-9]+$ ]] || { echo "--dias debe ser un número" >&2; exit 1; }

# Construye la expresión de find: -name a -o -name b ...
expr=()
for n in "${NOMBRES[@]}"; do
  if [[ ${#expr[@]} -gt 0 ]]; then expr+=(-o); fi
  expr+=(-name "$n")
done
filtro_tiempo=()
if [[ "$DIAS" -gt 0 ]]; then filtro_tiempo=(-mtime "+$DIAS"); fi

# -prune evita entrar dentro de una carpeta ya encontrada (node_modules anidados)
mapfile -d '' encontrados < <(find "$DIR" -type d \( "${expr[@]}" \) "${filtro_tiempo[@]}" -prune -print0 2>/dev/null)

if [[ ${#encontrados[@]} -eq 0 ]]; then
  echo "No se encontraron carpetas para limpiar en $DIR."
  exit 0
fi

total_kb=0
for d in "${encontrados[@]}"; do
  kb=$(du -sk "$d" 2>/dev/null | cut -f1)
  total_kb=$((total_kb + kb))
  printf '%10s  %s\n' "$(numfmt --to=iec --from-unit=1024 "$kb")" "$d"
done
echo "----------"
echo "Total: $(numfmt --to=iec --from-unit=1024 "$total_kb") en ${#encontrados[@]} carpetas."

if [[ $EJECUTAR -eq 0 ]]; then
  echo "(dry-run) No se borró nada. Usa --ejecutar para eliminar."
  exit 0
fi

read -r -p "¿Borrar estas ${#encontrados[@]} carpetas? Escribe 'si' para confirmar: " resp
if [[ "$resp" != "si" ]]; then
  echo "Cancelado."
  exit 0
fi
for d in "${encontrados[@]}"; do
  rm -rf -- "${d:?}"
done
echo "Eliminadas ${#encontrados[@]} carpetas."
