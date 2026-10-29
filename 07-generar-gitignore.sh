#!/usr/bin/env bash
# 07-generar-gitignore.sh
# Genera un .gitignore combinando plantillas integradas (sin internet).
# Por defecto imprime en la salida estándar; con -o escribe a un archivo.
set -euo pipefail

SALIDA=""
FORZAR=0
PLANTILLAS=(python node go rust java php web linux macos windows vscode jetbrains)

uso() {
  cat <<'AYUDA'
Uso: 07-generar-gitignore.sh [opciones] PLANTILLA [PLANTILLA...]

Combina plantillas de .gitignore incluidas en el script. No usa internet.

Opciones:
  -o, --salida ARCHIVO  Escribe en ARCHIVO (no sobrescribe si ya existe).
  -f, --forzar          Permite sobrescribir ARCHIVO.
  -l, --listar          Lista las plantillas disponibles.
  -h, --help            Muestra esta ayuda.

Ejemplos:
  07-generar-gitignore.sh python linux vscode > .gitignore
  07-generar-gitignore.sh -o .gitignore node macos jetbrains
AYUDA
}

plantilla() {
  case "$1" in
    python) cat <<'T'
__pycache__/
*.py[cod]
*.egg-info/
.eggs/
build/
dist/
.venv/
venv/
.pytest_cache/
.mypy_cache/
.ruff_cache/
.coverage
htmlcov/
.ipynb_checkpoints/
.env
T
    ;;
    node) cat <<'T'
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
.pnpm-store/
dist/
build/
coverage/
.next/
.nuxt/
.turbo/
.parcel-cache/
.vite/
.env
.env.*.local
T
    ;;
    go) cat <<'T'
# Binarios
*.exe
*.test
*.out
/bin/
# Espacio de trabajo local
go.work
go.work.sum
vendor/
T
    ;;
    rust) cat <<'T'
/target/
# Cargo.lock se versiona en binarios; descoméntalo solo en librerías
# Cargo.lock
**/*.rs.bk
T
    ;;
    java) cat <<'T'
*.class
*.jar
*.war
target/
build/
.gradle/
out/
hs_err_pid*
T
    ;;
    php) cat <<'T'
/vendor/
.phpunit.result.cache
.php-cs-fixer.cache
.env
T
    ;;
    web) cat <<'T'
dist/
.cache/
*.map
.sass-cache/
.env
T
    ;;
    linux) cat <<'T'
*~
.directory
.Trash-*
.nfs*
T
    ;;
    macos) cat <<'T'
.DS_Store
.AppleDouble
.LSOverride
._*
T
    ;;
    windows) cat <<'T'
Thumbs.db
ehthumbs.db
Desktop.ini
$RECYCLE.BIN/
*.lnk
T
    ;;
    vscode) cat <<'T'
.vscode/*
!.vscode/settings.json
!.vscode/extensions.json
!.vscode/launch.json
T
    ;;
    jetbrains) cat <<'T'
.idea/
*.iml
T
    ;;
    *) return 1 ;;
  esac
}

elegidas=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--salida) SALIDA="${2:?Falta ARCHIVO}"; shift ;;
    -f|--forzar) FORZAR=1 ;;
    -l|--listar) printf '%s\n' "${PLANTILLAS[@]}"; exit 0 ;;
    -h|--help) uso; exit 0 ;;
    -*) echo "Opción desconocida: $1" >&2; exit 1 ;;
    *) elegidas+=("${1,,}") ;;
  esac
  shift
done

[[ ${#elegidas[@]} -gt 0 ]] || { uso >&2; exit 1; }

# Valida todas antes de escribir nada
for p in "${elegidas[@]}"; do
  if ! plantilla "$p" >/dev/null; then
    echo "Plantilla desconocida: $p. Disponibles: ${PLANTILLAS[*]}" >&2
    exit 1
  fi
done

generar() {
  echo "# .gitignore generado el $(date +%Y-%m-%d) con: ${elegidas[*]}"
  local vistas="" p linea
  for p in "${elegidas[@]}"; do
    echo
    echo "### $p"
    # Evita repetir reglas que ya aparecieron en otra plantilla
    while IFS= read -r linea; do
      if [[ -n "$linea" && "$linea" != \#* ]]; then
        if grep -qxF -- "$linea" <<<"$vistas"; then continue; fi
        vistas+="$linea"$'\n'
      fi
      printf '%s\n' "$linea"
    done < <(plantilla "$p")
  done
}

if [[ -z "$SALIDA" ]]; then
  generar
else
  if [[ -e "$SALIDA" && $FORZAR -eq 0 ]]; then
    echo "Ya existe $SALIDA. Usa --forzar para sobrescribirlo." >&2
    exit 1
  fi
  generar > "$SALIDA"
  echo "Escrito $SALIDA ($(wc -l < "$SALIDA") líneas)."
fi
