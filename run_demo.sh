#!/usr/bin/env bash
set -euo pipefail

# Asistente de demo para vídeo del TFM.
# Flujo:
# 1) Abrir la presentación.
# 2) Pausar por bloques para narración.
# 3) Ejecutar validación completa de hipótesis en Proxmox (CT Vault).
# 4) Mostrar resumen compacto con veredicto final.
#
# Uso:
#   bash run_demo.sh
#
# Variables opcionales:
#   PROXMOX_USER=tfm-test
#   PROXMOX_HOST=proxmox
#   SSH_KEY_PATH=$HOME/.ssh/tfm_proxmox_temp_2026
#   VAULT_CT_ID=502
#   ALLOW_FALLBACK=yes|no
#   VAULT_ADMIN_TOKEN=<token>    # opcional, para evitar prompt
#   AUTO_NEXT=yes|no             # yes: sin pausas interactivas
#   OPEN_PRESENTATION=yes|no      # no: no abre PDF automáticamente
#   SLIDE_CONTROL=yes|no          # yes: enviar "siguiente diapositiva"
#   PRESENTATION_APP="Microsoft Edge"
#   SLIDE_KEY=right|space         # tecla principal para avanzar
#   TOTAL_STEPS=17                # número total de "siguientes"
#   VALIDATION_STEP=11            # paso donde ejecutar validación técnica
#   KEYCHAIN_SERVICE=tfm-vault-admin-token
#   KEYCHAIN_ACCOUNT=proxmox-vault-admin
#   AUTO_SCREEN_RECORD=yes|no     # graba pantalla (macOS) con screencapture
#   SCREEN_RECORD_AUDIO=yes|no   # incluye audio de micrófono (-g) en screencapture
#   SCREEN_RECORD_CURSOR=yes|no  # captura el cursor en vídeo (-C) en screencapture
#   SCREEN_RECORD_AUDIO_DEVICE_ID=<id>  # opcional: usa -G<id> para elegir dispositivo de micrófono
#   SCREEN_RECORD_DISPLAY=1       # display principal por defecto
#   SCREEN_RECORD_DIR=artifacts/recordings
#   SCREEN_RECORD_FILE=<ruta>     # opcional: override del archivo .mov
#   SCREEN_RECORD_CLEAN_BEFORE=yes|no  # limpia punteros 'latest' antes de grabar
#   SCREEN_RECORD_STOP_TIMEOUT_SEC=4   # tiempo máximo para parar la grabación
#   SCREEN_RECORD_VIDEO_MARKER=yes|no  # muestra una notificación visible (osascript) al inicio/fin
#
#   PRESENTATION_OPEN_DELAY_SEC=1     # espera tras abrir antes de mandar "Home" / primera navegación
#   PRESENTATION_FORCE_COVER_RETRIES=3 # reintentos para asegurarnos de caer en portada
#   PRESENTATION_FORCE_COVER_DELAY_SEC=0.2 # espera entre reintentos

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if ! command -v ssh >/dev/null 2>&1; then
  echo "[ERROR] No se encontró 'ssh' en el sistema." >&2
  exit 1
fi
if ! command -v rg >/dev/null 2>&1; then
  echo "[ERROR] No se encontró 'rg' en el sistema." >&2
  exit 1
fi

PROXMOX_USER="${PROXMOX_USER:-tfm-test}"
PROXMOX_HOST="${PROXMOX_HOST:-proxmox}"
VAULT_CT_ID="${VAULT_CT_ID:-502}"
SSH_KEY_PATH="${SSH_KEY_PATH:-}"
ALLOW_FALLBACK="${ALLOW_FALLBACK:-yes}"
AUTO_NEXT="${AUTO_NEXT:-no}"
OPEN_PRESENTATION="${OPEN_PRESENTATION:-yes}"
SLIDE_CONTROL="${SLIDE_CONTROL:-yes}"
PRESENTATION_APP="${PRESENTATION_APP:-Microsoft Edge}"
SLIDE_KEY="${SLIDE_KEY:-right}"
TOTAL_STEPS="${TOTAL_STEPS:-17}"
VALIDATION_STEP="${VALIDATION_STEP:-11}"
KEYCHAIN_SERVICE="${KEYCHAIN_SERVICE:-tfm-vault-admin-token}"
KEYCHAIN_ACCOUNT="${KEYCHAIN_ACCOUNT:-proxmox-vault-admin}"
SSH_TARGET="${PROXMOX_USER}@${PROXMOX_HOST}"
PRESENTATION_FILE="${ROOT_DIR}/artifacts/presentation/presentacion_tfm_marp.pdf"

AUTO_SCREEN_RECORD="${AUTO_SCREEN_RECORD:-no}"
SCREEN_RECORD_AUDIO="${SCREEN_RECORD_AUDIO:-yes}"
SCREEN_RECORD_CURSOR="${SCREEN_RECORD_CURSOR:-yes}"
SCREEN_RECORD_AUDIO_DEVICE_ID="${SCREEN_RECORD_AUDIO_DEVICE_ID:-}"
SCREEN_RECORD_DISPLAY="${SCREEN_RECORD_DISPLAY:-1}"
SCREEN_RECORD_DIR="${SCREEN_RECORD_DIR:-artifacts/recordings}"
DEMO_RECORD_STAMP="$(date +%Y%m%d_%H%M%S)"
SCREEN_RECORD_FILE="${SCREEN_RECORD_FILE:-$SCREEN_RECORD_DIR/video_demo_${DEMO_RECORD_STAMP}.mov}"
SCREEN_RECORD_LATEST_LINK="${SCREEN_RECORD_LATEST_LINK:-$SCREEN_RECORD_DIR/latest_video_demo.mov}"
SCREEN_RECORD_LAST_PATH_FILE="${SCREEN_RECORD_LAST_PATH_FILE:-$SCREEN_RECORD_DIR/last_video_demo_path.txt}"
SCREEN_RECORD_CLEAN_BEFORE="${SCREEN_RECORD_CLEAN_BEFORE:-yes}"
SCREEN_RECORD_STOP_TIMEOUT_SEC="${SCREEN_RECORD_STOP_TIMEOUT_SEC:-4}"
SCREEN_RECORD_VIDEO_MARKER="${SCREEN_RECORD_VIDEO_MARKER:-no}"
PRESENTATION_OPEN_DELAY_SEC="${PRESENTATION_OPEN_DELAY_SEC:-1}"
PRESENTATION_FORCE_COVER_RETRIES="${PRESENTATION_FORCE_COVER_RETRIES:-3}"
PRESENTATION_FORCE_COVER_DELAY_SEC="${PRESENTATION_FORCE_COVER_DELAY_SEC:-0.2}"
recording_pid=""

mkdir -p artifacts/validation
RAW_OUT="artifacts/validation/demo_run_results.txt"
SUMMARY_OUT="artifacts/validation/demo_run_summary.txt"
LAST_GOOD_RAW="artifacts/validation/last_known_good_results.txt"
LAST_GOOD_SUMMARY="artifacts/validation/last_known_good_summary.txt"

SSH_OPTS=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new)
if [[ -n "$SSH_KEY_PATH" ]]; then
  SSH_OPTS+=(-i "$SSH_KEY_PATH")
fi

narrate() {
  local text="$1"
  echo "[PRESENTACIÓN] $text"
}

wait_demo_continue() {
  local msg="$1"
  if [[ "$AUTO_NEXT" != "yes" ]]; then
    printf "%s" "$msg"
    read -r _
  else
    sleep 0.4
  fi
}

open_presentation() {
  if [[ "$OPEN_PRESENTATION" != "yes" ]]; then
    echo "[INFO] Presentación no abierta automáticamente (OPEN_PRESENTATION=no)."
    return 0
  fi
  if [[ ! -f "$PRESENTATION_FILE" ]]; then
    echo "[ERROR] No existe la presentación: $PRESENTATION_FILE" >&2
    return 1
  fi
  if ! command -v open >/dev/null 2>&1; then
    echo "[ERROR] Comando 'open' no disponible en este sistema." >&2
    return 1
  fi

  # Intenta abrir en la app indicada; si falla, usa la asociacion por defecto.
  set +e
  open -a "$PRESENTATION_APP" "$PRESENTATION_FILE" >/dev/null 2>&1
  rc_app=$?
  set -e
  if [[ $rc_app -ne 0 ]]; then
    open "$PRESENTATION_FILE" >/dev/null 2>&1
    echo "[WARN] No se pudo abrir con '$PRESENTATION_APP'. Abierta con app por defecto."
  else
    echo "[INFO] Presentación abierta con '$PRESENTATION_APP'."
  fi
  echo "[INFO] Archivo: $PRESENTATION_FILE"

  # Espera y reintenta para reducir fallos de "timing" al posicionarnos en portada.
  sleep "$PRESENTATION_OPEN_DELAY_SEC"
  for _ in $(seq 1 "$PRESENTATION_FORCE_COVER_RETRIES"); do
    force_cover_slide || true
    sleep "$PRESENTATION_FORCE_COVER_DELAY_SEC"
  done
}

advance_slide() {
  if [[ "$SLIDE_CONTROL" != "yes" ]]; then
    return 0
  fi
  if ! command -v osascript >/dev/null 2>&1; then
    return 1
  fi
  local script_keycode="124"
  if [[ "$SLIDE_KEY" == "space" ]]; then
    script_keycode="49"
  fi
  osascript >/dev/null 2>&1 <<OSA
tell application "$PRESENTATION_APP" to activate
delay 0.15
tell application "System Events"
  key code $script_keycode
end tell
OSA
  return $?
}

advance_or_warn() {
  if ! advance_slide; then
    echo "[WARN] No se pudo avanzar diapositiva por script."
    echo "       Revisa permisos de Accesibilidad/Automatizacion para Cursor/Terminal."
  fi
}

video_marker() {
  if [[ "$SCREEN_RECORD_VIDEO_MARKER" != "yes" ]]; then
    return 0
  fi
  if ! command -v osascript >/dev/null 2>&1; then
    return 0
  fi
  local text="$1"
  # Notificación visible en el vídeo (se apoya en "display notification").
  osascript >/dev/null 2>&1 <<OSA
display notification "$text" with title "TFM Demo"
OSA
}

start_screen_recording() {
  if [[ "$AUTO_SCREEN_RECORD" != "yes" ]]; then
    return 0
  fi
  if ! command -v screencapture >/dev/null 2>&1; then
    echo "[WARN] 'screencapture' no está disponible. Se omite grabación de pantalla." >&2
    return 0
  fi

  mkdir -p "$SCREEN_RECORD_DIR"
  if [[ "$SCREEN_RECORD_CLEAN_BEFORE" == "yes" ]]; then
    # Evita que, si falla la grabación, el bundle copie un vídeo viejo.
    rm -f "$SCREEN_RECORD_LATEST_LINK" "$SCREEN_RECORD_LAST_PATH_FILE" "$SCREEN_RECORD_FILE" >/dev/null 2>&1 || true
  else
    rm -f "$SCREEN_RECORD_FILE" >/dev/null 2>&1 || true
  fi

  local cmd=(screencapture -v -D"$SCREEN_RECORD_DISPLAY")
  if [[ "$SCREEN_RECORD_CURSOR" == "yes" ]]; then
    cmd+=(-C)
  fi
  if [[ "$SCREEN_RECORD_AUDIO" == "yes" ]]; then
    if [[ -n "${SCREEN_RECORD_AUDIO_DEVICE_ID:-}" ]]; then
      cmd+=(-G"$SCREEN_RECORD_AUDIO_DEVICE_ID")
    else
      cmd+=(-g)
    fi
  fi
  cmd+=("$SCREEN_RECORD_FILE")

  echo "[INFO] Grabando pantalla -> $SCREEN_RECORD_FILE (display=$SCREEN_RECORD_DISPLAY, cursor=$SCREEN_RECORD_CURSOR, audio=$SCREEN_RECORD_AUDIO)"
  "${cmd[@]}" >/dev/null 2>&1 &
  recording_pid="$!"

  # Pequeña espera para asegurar que el archivo se crea tras iniciar.
  sleep 0.3
}

stop_screen_recording() {
  if [[ -z "${recording_pid}" ]]; then
    return 0
  fi

  # screencapture finaliza al recibir INT, pero usamos timeout y fallback por robustez.
  if kill -0 "$recording_pid" >/dev/null 2>&1; then
    kill -INT "$recording_pid" >/dev/null 2>&1 || true

    local timeout_sec="$SCREEN_RECORD_STOP_TIMEOUT_SEC"
    local start_s
    start_s="$(date +%s)"
    while kill -0 "$recording_pid" >/dev/null 2>&1; do
      if (( "$(date +%s)" - start_s >= timeout_sec )); then
        break
      fi
      sleep 0.2
    done

    if kill -0 "$recording_pid" >/dev/null 2>&1; then
      echo "[WARN] screencapture no paró en ${timeout_sec}s; aplicando fallback (TERM/KILL)." >&2
      kill -TERM "$recording_pid" >/dev/null 2>&1 || true
      sleep 0.2
      kill -KILL "$recording_pid" >/dev/null 2>&1 || true
    fi
  fi

  wait "$recording_pid" >/dev/null 2>&1 || true
  recording_pid=""

  if [[ -f "$SCREEN_RECORD_FILE" ]]; then
    echo "[INFO] Vídeo guardado: $SCREEN_RECORD_FILE"
    # Punto estable para que el bundle recoja el vídeo exacto de esta ejecución.
    ln -sf "$SCREEN_RECORD_FILE" "$SCREEN_RECORD_LATEST_LINK" >/dev/null 2>&1 || true
    printf "%s\n" "$SCREEN_RECORD_FILE" > "$SCREEN_RECORD_LAST_PATH_FILE" 2>/dev/null || true
  else
    echo "[WARN] No se pudo confirmar el vídeo grabado: $SCREEN_RECORD_FILE" >&2
  fi
}

cleanup_demo() {
  stop_screen_recording || true
  unset VAULT_ADMIN_TOKEN || true
}

trap cleanup_demo EXIT INT TERM

force_cover_slide() {
  if [[ "$SLIDE_CONTROL" != "yes" ]]; then
    return 0
  fi
  if ! command -v osascript >/dev/null 2>&1; then
    return 1
  fi
  osascript >/dev/null 2>&1 <<OSA
tell application "$PRESENTATION_APP" to activate
delay 0.25
tell application "System Events"
  key code 115
  delay 0.05
  key code 115
end tell
OSA
  return $?
}

load_admin_token_from_keychain() {
  if [[ -n "${VAULT_ADMIN_TOKEN:-}" ]]; then
    return 0
  fi
  if ! command -v security >/dev/null 2>&1; then
    return 0
  fi
  set +e
  VAULT_ADMIN_TOKEN="$(security find-generic-password -a "$KEYCHAIN_ACCOUNT" -s "$KEYCHAIN_SERVICE" -w 2>/dev/null)"
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    VAULT_ADMIN_TOKEN=""
  fi
}

prepare_admin_token() {
  load_admin_token_from_keychain
  if [[ -n "${VAULT_ADMIN_TOKEN:-}" ]]; then
    echo "[INFO] VAULT_ADMIN_TOKEN cargado desde Keychain (${KEYCHAIN_SERVICE}/${KEYCHAIN_ACCOUNT})."
    return 0
  fi
  echo "[INFO] VAULT_ADMIN_TOKEN no encontrado en Keychain. Se solicitará por consola."
  printf "VAULT_ADMIN_TOKEN: " >&2
  read -r -s VAULT_ADMIN_TOKEN
  printf "\n" >&2
  if [[ -z "${VAULT_ADMIN_TOKEN:-}" ]]; then
    echo "[ERROR] VAULT_ADMIN_TOKEN vacío." >&2
    exit 1
  fi
}

run_validation() {
  narrate "Se lanza la prueba técnica para validar emisión, revocación y control de acceso."
  wait_demo_continue "Pulsa ENTER para lanzar la validación..."

  prepare_admin_token
  echo "[INFO] Ejecutando validación completa en ${SSH_TARGET}..."
  set +e
  ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "sudo -n pct exec ${VAULT_CT_ID} -- sh -lc 'read -r VAULT_TOKEN; export VAULT_TOKEN; if [ -x /root/proxmox_validation_suite.sh ]; then bash /root/proxmox_validation_suite.sh; else echo \"[ERROR] No existe /root/proxmox_validation_suite.sh\" >&2; exit 2; fi'" <<<"$VAULT_ADMIN_TOKEN" \
    | sed -E 's/^(lease_id=).*/\1[REDACTED]/; s/^(db_user=).*/\1[REDACTED]/' \
    | tee "$RAW_OUT"
  remote_rc=${PIPESTATUS[0]}
  set -e

  if [[ "$remote_rc" -ne 0 ]]; then
    echo "[WARN] Fallo remoto (rc=${remote_rc})."
    if [[ "$ALLOW_FALLBACK" == "yes" && -f "$LAST_GOOD_RAW" ]]; then
      echo "[WARN] Plan B activo: usando última evidencia válida guardada."
      cp "$LAST_GOOD_RAW" "$RAW_OUT"
    else
      echo "[ERROR] No hay respaldo local para plan B." >&2
      exit "$remote_rc"
    fi
  fi

  echo "[INFO] Resumen compacto para vídeo:"
  rg "^(issue_ms|revoke_ms|lease_ttl_seconds|pre_revoke_query|post_revoke_query|post_revoke_role_exists|unauthorized_token_access|hypothesis_overall)=" "$RAW_OUT" | tee "$SUMMARY_OUT"

  local issue_ms revoke_ms ttl pre_ok post_ok role_ok unauth_ok verdict
  issue_ms="$(awk -F= '$1=="issue_ms"{print $2; exit}' "$SUMMARY_OUT")"
  revoke_ms="$(awk -F= '$1=="revoke_ms"{print $2; exit}' "$SUMMARY_OUT")"
  ttl="$(awk -F= '$1=="lease_ttl_seconds"{print $2; exit}' "$SUMMARY_OUT")"
  pre_ok="$(awk -F= '$1=="pre_revoke_query"{print $2; exit}' "$SUMMARY_OUT")"
  post_ok="$(awk -F= '$1=="post_revoke_query"{print $2; exit}' "$SUMMARY_OUT")"
  role_ok="$(awk -F= '$1=="post_revoke_role_exists"{print $2; exit}' "$SUMMARY_OUT")"
  unauth_ok="$(awk -F= '$1=="unauthorized_token_access"{print $2; exit}' "$SUMMARY_OUT")"
  verdict="$(awk -F= '$1=="hypothesis_overall"{print $2; exit}' "$SUMMARY_OUT")"

  echo
  echo "[RESUMEN]"
  echo "- Emisión: ${issue_ms:-na} ms | Revocación: ${revoke_ms:-na} ms | TTL: ${ttl:-na} s"
  echo "- Prueba positiva: ${pre_ok:-na}"
  echo "- Revocación efectiva: ${post_ok:-na} | Rol eliminado: ${role_ok:-na}"
  echo "- Acceso no autorizado: ${unauth_ok:-na}"
  echo "- Veredicto final: ${verdict:-na}"

  cp "$RAW_OUT" "$LAST_GOOD_RAW"
  cp "$SUMMARY_OUT" "$LAST_GOOD_SUMMARY"

  narrate "Resumen: emisión y revocación correctas, bloqueo no autorizado y veredicto."
  wait_demo_continue "Pulsa ENTER para continuar con la siguiente diapositiva..."
}

step_text() {
  case "$1" in
    1) echo "Problema: Secret Sprawl y riesgo operativo." ;;
    2) echo "Marco: Zero Trust, NIS2 y DORA." ;;
    3) echo "Hipótesis y tesis del TFM." ;;
    4) echo "Arquitectura lógica en tres planos." ;;
    5) echo "Topología del laboratorio on-premise." ;;
    6) echo "Trazabilidad normativa -> control -> evidencia." ;;
    7) echo "Secret Zero sin hardcoding." ;;
    8) echo "Flujo OIDC -> Vault -> PostgreSQL." ;;
    9) echo "Preparación de host y automatización." ;;
    10) echo "IaC reproducible con Terraform/Ansible." ;;
    11) echo "Demo técnica: ejecución de validación end-to-end." ;;
    12) echo "Resultados: emisión dinámica y revocación." ;;
    13) echo "Resultados: auditoría y detección." ;;
    14) echo "Resultados: reproducibilidad." ;;
    15) echo "Discusion y limites." ;;
    16) echo "Backlog y trabajo futuro." ;;
    17) echo "Conclusiones y cierre." ;;
    *) echo "Paso de presentación." ;;
  esac
}

echo "=============================================="
echo " DEMO TFM - GUÍA DE EJECUCIÓN (5 minutos)"
echo "=============================================="
echo "[INFO] App de presentación: $PRESENTATION_APP"
echo "[INFO] Control de diapositivas: $SLIDE_CONTROL (SLIDE_KEY=$SLIDE_KEY)"
echo "[INFO] TOTAL_STEPS=$TOTAL_STEPS | VALIDATION_STEP=$VALIDATION_STEP"

echo
echo "=== Abrir presentación ==="
start_screen_recording # (si AUTO_SCREEN_RECORD=yes) empieza antes de abrir el visor

open_presentation

if [[ "$AUTO_NEXT" != "yes" ]]; then
  printf "Pulsa ENTER para iniciar la secuencia de diapositivas..."
  read -r _
fi
# Arranque sincronizado: portada -> diapositiva 1.
advance_or_warn

for step in $(seq 1 "$TOTAL_STEPS"); do
  if [[ "$step" -gt 1 ]]; then
    if [[ "$AUTO_NEXT" != "yes" ]]; then
      printf "Pulsa ENTER para siguiente..."
      read -r _
    else
      sleep 0.4
    fi
    advance_or_warn
  fi

  echo
  echo "=== Paso $step/$TOTAL_STEPS ==="
  narrate "$(step_text "$step")"

  if [[ "$step" -eq "$VALIDATION_STEP" ]]; then
    video_marker "INICIO_VALIDACION (TFM)"
    run_validation
    video_marker "FIN_VALIDACION (TFM)"
  fi
done

# Parada explícita para asegurar que el .mov queda cerrado antes del resumen.
stop_screen_recording

echo
echo "[OK] Validación TFM completada."
echo "     Veredicto: $(rg '^hypothesis_overall=' "$SUMMARY_OUT" | awk -F= '{print $2}' | tr -d '[:space:]')"
echo "     Resumen:   $SUMMARY_OUT"
echo "     Detalle:   $RAW_OUT"
unset VAULT_ADMIN_TOKEN
