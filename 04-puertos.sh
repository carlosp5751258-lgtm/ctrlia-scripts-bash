#!/usr/bin/env bash
# 04-puertos.sh
# Lista los puertos TCP en escucha o muestra qué proceso usa un puerto
# concreto, con opción de terminarlo (siempre con confirmación por PID).
set -euo pipefail

PUERTO=""
MATAR=0
SENAL="TERM"

uso() {
  cat <<'AYUDA'
Uso: 04-puertos.sh [opciones] [PUERTO]

Sin PUERTO: lista todos los puertos TCP en escucha y su proceso.
Con PUERTO: muestra qué proceso lo usa.

Opciones:
  -k, --matar        Ofrece terminar el proceso que usa PUERTO (pide confirmación).
  -9, --forzar       Usa SIGKILL en lugar de SIGTERM (solo si TERM no basta).
  -h, --help         Muestra esta ayuda.

Ejemplos:
  04-puertos.sh            # ¿qué está escuchando?
  04-puertos.sh 3000       # ¿quién ocupa el 3000?
  04-puertos.sh -k 3000    # liberar el 3000

Nota: para ver procesos de otros usuarios (p. ej. root) ejecuta con sudo.
AYUDA
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -k|--matar) MATAR=1 ;;
    -9|--forzar) SENAL="KILL" ;;
    -h|--help) uso; exit 0 ;;
    -*) echo "Opción desconocida: $1" >&2; exit 1 ;;
    *) PUERTO="$1" ;;
  esac
  shift
done

command -v ss >/dev/null 2>&1 || { echo "Se necesita 'ss' (paquete iproute2)." >&2; exit 1; }

if [[ -z "$PUERTO" ]]; then
  echo "Puertos TCP en escucha:"
  # Columnas de ss -ltnpH: estado recv send local remoto proceso
  ss -ltnpH | awk '{print $4, $6}' | sort -u | while read -r dir proc; do
    printf '  %-28s %s\n' "$dir" "${proc:-(sin permiso para ver el proceso)}"
  done
  exit 0
fi

if ! [[ "$PUERTO" =~ ^[0-9]+$ ]] || (( PUERTO < 1 || PUERTO > 65535 )); then
  echo "Puerto inválido: $PUERTO" >&2; exit 1
fi

# Extrae los PID de la salida de ss: users:(("node",pid=1234,fd=20))
mapfile -t pids < <(ss -ltnpH "sport = :$PUERTO" | grep -o 'pid=[0-9]*' | cut -d= -f2 | sort -u || true)

if [[ ${#pids[@]} -eq 0 ]]; then
  if ss -ltnH "sport = :$PUERTO" | grep -q .; then
    echo "El puerto $PUERTO está en uso, pero no tienes permiso para ver el proceso. Prueba con sudo."
    exit 2
  fi
  echo "El puerto $PUERTO está libre."
  exit 0
fi

echo "Puerto $PUERTO en uso por:"
for pid in "${pids[@]}"; do
  ps -o pid=,user=,etime=,cmd= -p "$pid" | sed 's/^/  /'
done

[[ $MATAR -eq 1 ]] || { echo "Usa -k para terminar el proceso."; exit 0; }

for pid in "${pids[@]}"; do
  read -r -p "¿Enviar SIG$SENAL al PID $pid? [s/N] " resp || resp=""
  if [[ "$resp" =~ ^[sS]$ ]]; then
    kill -s "$SENAL" "$pid" && echo "Señal enviada a $pid."
  else
    echo "PID $pid sin tocar."
  fi
done
