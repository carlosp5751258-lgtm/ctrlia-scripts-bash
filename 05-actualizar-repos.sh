#!/usr/bin/env bash
# 05-actualizar-repos.sh
# Recorre los repositorios git de una carpeta y hace "git pull --ff-only"
# en cada uno. Se salta los repos con cambios sin confirmar o sin upstream.
set -euo pipefail

DIR="."
PROFUNDIDAD=2
DRY_RUN=0

uso() {
  cat <<'AYUDA'
Uso: 05-actualizar-repos.sh [opciones] [DIRECTORIO]

Busca repositorios git dentro de DIRECTORIO y los actualiza de forma segura:
  - solo fast-forward (git pull --ff-only), nunca crea merges
  - se salta repos con cambios sin confirmar
  - se salta ramas sin upstream configurado

Opciones:
  -p, --profundidad N  Niveles de subcarpetas a explorar (por defecto: 2).
  -n, --dry-run        Solo hace "git fetch" y muestra cuántos commits nuevos hay.
  -h, --help           Muestra esta ayuda.

Código de salida: 0 si no hubo errores, 1 si algún repo falló.
AYUDA
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--profundidad) PROFUNDIDAD="${2:?Falta N}"; shift ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help) uso; exit 0 ;;
    -*) echo "Opción desconocida: $1" >&2; exit 1 ;;
    *) DIR="$1" ;;
  esac
  shift
done
[[ -d "$DIR" ]] || { echo "No existe: $DIR" >&2; exit 1; }
[[ "$PROFUNDIDAD" =~ ^[0-9]+$ ]] || { echo "--profundidad debe ser un número" >&2; exit 1; }

ok=0; saltados=0; errores=0
# Cada ".git" encontrado indica un repositorio (carpeta, o archivo en worktrees)
while IFS= read -r -d '' gitdir; do
  repo="$(dirname "$gitdir")"
  rama="$(git -C "$repo" symbolic-ref --short -q HEAD || echo '(HEAD separado)')"
  printf '\n▶ %s [%s]\n' "$repo" "$rama"

  if [[ -n "$(git -C "$repo" status --porcelain)" ]]; then
    echo "  ↷ Cambios sin confirmar: se omite."; saltados=$((saltados + 1)); continue
  fi
  if ! git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    echo "  ↷ Sin upstream configurado: se omite."; saltados=$((saltados + 1)); continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    if git -C "$repo" fetch --quiet; then
      nuevos="$(git -C "$repo" rev-list --count 'HEAD..@{u}')"
      echo "  (dry-run) commits nuevos en remoto: $nuevos"; ok=$((ok + 1))
    else
      echo "  ✖ Falló git fetch."; errores=$((errores + 1))
    fi
  else
    if git -C "$repo" pull --ff-only --quiet; then
      echo "  ✔ Al día: $(git -C "$repo" log -1 --format='%h %s')"; ok=$((ok + 1))
    else
      echo "  ✖ No se pudo hacer fast-forward (¿ramas divergentes?)."; errores=$((errores + 1))
    fi
  fi
done < <(find "$DIR" -mindepth 1 -maxdepth "$((PROFUNDIDAD + 1))" -name .git -print0 | sort -z)

printf '\nResumen: %d ok, %d omitidos, %d con error.\n' "$ok" "$saltados" "$errores"
[[ $errores -eq 0 ]]
