#!/usr/bin/env bash
# 12-git-limpiar-ramas.sh
# Lista (y opcionalmente borra) las ramas locales ya fusionadas en la rama
# base. Por defecto es dry-run. Usa "git branch -d", que se niega a borrar
# ramas con trabajo no fusionado.
set -euo pipefail

BASE=""
EJECUTAR=0
REMOTAS=0
REMOTO="origin"
PROTEGIDAS="main master develop dev staging production"

uso() {
  cat <<'AYUDA'
Uso: 12-git-limpiar-ramas.sh [opciones]

Ejecútalo dentro de un repositorio git.

Opciones:
  -b, --base RAMA     Rama de referencia (por defecto: main o master).
  -x, --ejecutar      Borra de verdad (pide confirmación). Sin esto: dry-run.
  -r, --remotas       Incluye ramas remotas fusionadas (git push REMOTO --delete).
      --remoto NOMBRE Remoto a usar (por defecto: origin).
  -h, --help          Muestra esta ayuda.

Nunca se borran: la rama actual, la base ni main/master/develop/dev/staging/production.

Nota: las ramas fusionadas con "squash" o "rebase" en GitHub/GitLab no
aparecen como fusionadas para git; revísalas a mano.
AYUDA
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--base) BASE="${2:?Falta RAMA}"; shift ;;
    -x|--ejecutar) EJECUTAR=1 ;;
    -r|--remotas) REMOTAS=1 ;;
    --remoto) REMOTO="${2:?Falta NOMBRE}"; shift ;;
    -h|--help) uso; exit 0 ;;
    *) echo "Opción desconocida: $1" >&2; exit 1 ;;
  esac
  shift
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "No estás dentro de un repositorio git." >&2; exit 1; }

if [[ -z "$BASE" ]]; then
  for candidata in main master; do
    if git show-ref --verify --quiet "refs/heads/$candidata"; then BASE="$candidata"; break; fi
  done
fi
[[ -n "$BASE" ]] || { echo "No encontré main ni master; usa --base." >&2; exit 1; }
git show-ref --verify --quiet "refs/heads/$BASE" || { echo "No existe la rama local $BASE." >&2; exit 1; }

actual="$(git symbolic-ref --short -q HEAD || true)"
es_protegida() {
  [[ "$1" == "$BASE" || "$1" == "$actual" || " $PROTEGIDAS " == *" $1 "* ]]
}

# Ramas locales fusionadas en BASE
locales=()
while IFS= read -r rama; do
  es_protegida "$rama" || locales+=("$rama")
done < <(git for-each-ref --merged="$BASE" --format='%(refname:short)' refs/heads/)

# Ramas remotas fusionadas (opcional)
remotas=()
if [[ $REMOTAS -eq 1 ]]; then
  git fetch --prune --quiet "$REMOTO"
  while IFS= read -r ref; do
    rama="${ref#"$REMOTO"/}"
    [[ "$rama" == "HEAD" || "$ref" == "$REMOTO" ]] && continue
    es_protegida "$rama" || remotas+=("$rama")
  done < <(git for-each-ref --merged="$BASE" --format='%(refname:short)' "refs/remotes/$REMOTO/")
fi

echo "Base: $BASE   Rama actual: ${actual:-(HEAD separado)}"
echo "Ramas locales fusionadas (${#locales[@]}):"
if [[ ${#locales[@]} -gt 0 ]]; then printf '  %s\n' "${locales[@]}"; fi
if [[ $REMOTAS -eq 1 ]]; then
  echo "Ramas remotas fusionadas en $REMOTO (${#remotas[@]}):"
  if [[ ${#remotas[@]} -gt 0 ]]; then printf '  %s\n' "${remotas[@]}"; fi
fi

total=$(( ${#locales[@]} + ${#remotas[@]} ))
if [[ $total -eq 0 ]]; then echo "Nada que limpiar."; exit 0; fi
if [[ $EJECUTAR -eq 0 ]]; then
  echo "(dry-run) No se borró nada. Usa --ejecutar para borrar."
  exit 0
fi

read -r -p "¿Borrar estas $total ramas? [s/N] " resp || resp=""
[[ "$resp" =~ ^[sS]$ ]] || { echo "Cancelado."; exit 0; }

for rama in "${locales[@]}"; do
  git branch -d -- "$rama"
done
for rama in "${remotas[@]}"; do
  git push "$REMOTO" --delete "$rama"
done
echo "Limpieza terminada."
