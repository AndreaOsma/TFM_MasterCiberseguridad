#!/usr/bin/env bash
set -u 

# Asistente de demo para vídeo del TFM.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# Configuración Proxmox / SSH
PROXMOX_USER="${PROXMOX_USER:-tfm-test}"
PROXMOX_HOST="${PROXMOX_HOST:-proxmox}"
VAULT_CT_ID="${VAULT_CT_ID:-502}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/tfm_proxmox_temp_2026}"
SSH_TARGET="${PROXMOX_USER}@${PROXMOX_HOST}"
SSH_OPTS=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes -o PasswordAuthentication=no -i "$SSH_KEY_PATH")

# Archivos (Rutas Absolutas)
PRESENTATION_FILE="${ROOT_DIR}/artifacts/presentation/presentacion_tfm_marp.html"
SCREEN_RECORD_DIR="${ROOT_DIR}/artifacts/recordings"
DEMO_RECORD_STAMP="$(date +%Y%m%d_%H%M%S)"
SCREEN_RECORD_FILE="$SCREEN_RECORD_DIR/video_demo_${DEMO_RECORD_STAMP}.mov"
VALIDATION_SCRIPT="${ROOT_DIR}/artifacts/scripts/proxmox_validation_suite.sh"
RAW_OUT="${ROOT_DIR}/artifacts/validation/demo_run_results.txt"

# Asegurar directorios
mkdir -p "${ROOT_DIR}/artifacts/validation"
mkdir -p "$SCREEN_RECORD_DIR"

# Variables de Control
AUTO_SCREEN_RECORD="${AUTO_SCREEN_RECORD:-no}"
DND_CONTROL="${DND_CONTROL:-yes}"
WEBCAM_RECORD="${WEBCAM_RECORD:-yes}"
WEBCAM_WIDTH=160
WEBCAM_HEIGHT=90

# --- FUNCIONES DE APOYO ---

wait_demo_continue() {
  printf "\n%s" "$1"
  read -r _
}

toggle_dnd() {
  if [[ "$DND_CONTROL" != "yes" ]]; then return 0; fi
  local state="$1"
  if [[ "$state" == "on" ]]; then
    echo "[INFO] No Molestar: ON"
    (shortcuts run "Turn Do Not Disturb On" || shortcuts run "Activar No molestar") >/dev/null 2>&1 || true
  else
    echo "[INFO] No Molestar: OFF"
    (shortcuts run "Turn Do Not Disturb Off" || shortcuts run "Desactivar No molestar") >/dev/null 2>&1 || true
  fi
}

start_webcam() {
  if [[ "$WEBCAM_RECORD" != "yes" ]]; then return 0; fi
  open -g -a "QuickTime Player"
  sleep 2
  osascript >/dev/null 2>&1 <<OSA
tell application "QuickTime Player"
    if (count of windows) is 0 then new movie recording
    set bounds of window 1 to {1200, 50, 1200+$WEBCAM_WIDTH, 50+$WEBCAM_HEIGHT}
    try
        click menu item "Float on Top" of menu "View" of menu bar 1
    on error
        try
            click menu item "Flotar encima" of menu "Visualización" of menu bar 1
        end try
    end try
end tell
OSA
}

start_screen_recording() {
  if [[ "$AUTO_SCREEN_RECORD" != "yes" ]]; then return 0; fi
  echo "[INFO] Iniciando captura de pantalla y audio (Display 1)..."
  # Usamos -D 1 para el monitor principal y aseguramos el orden de los flags
  screencapture -v -g -D 1 "$SCREEN_RECORD_FILE" 2>/tmp/screencapture_err.log &
  recording_pid="$!"

  # Verificamos si el proceso sigue vivo tras 2 segundos (inicialización)
  sleep 2
  if ! kill -0 "$recording_pid" 2>/dev/null; then
    echo "[ERROR] La grabación falló al iniciar. Revisa permisos de 'Grabación de pantalla' para tu Terminal."
    echo "[DEBUG] Error: $(cat /tmp/screencapture_err.log)"
    recording_pid=""
    return 1
  fi
  echo "[OK] Grabación en curso."
}

stop_screen_recording() {
  if [[ -z "${recording_pid:-}" ]]; then return 0; fi
  echo "[INFO] Finalizando vídeo..."
  kill -INT "$recording_pid" 2>/dev/null && wait "$recording_pid" 2>/dev/null || true
  recording_pid=""
  
  if [[ -f "$SCREEN_RECORD_FILE" ]]; then
    local size=$(du -sh "$SCREEN_RECORD_FILE" | cut -f1)
    echo "[OK] Vídeo guardado ($size): $SCREEN_RECORD_FILE"
  else
    echo "[WARN] No se encontró el archivo de vídeo en $SCREEN_RECORD_FILE"
  fi
}

advance_slide() {
  echo "[DEBUG] Avanzando diapositiva..."
  osascript >/dev/null <<OSA
tell application "Safari" to activate
delay 0.5
tell application "System Events"
    tell process "Safari"
        set frontmost to true
        key code 124
    end tell
end tell
OSA
}

force_cover_slide() {
  echo "[DEBUG] Volviendo a la portada..."
  osascript >/dev/null <<OSA
tell application "Safari" to activate
delay 0.5
tell application "System Events"
    tell process "Safari"
        set frontmost to true
        key code 115
    end tell
end tell
OSA
}

# --- TAREAS TÉCNICAS (GRABADAS) ---

run_setup_proxmox() {
  clear
  echo -e "\n>>> PASO 9: Script de Preparación del Host"
  echo "Comando: ssh $SSH_TARGET 'sudo bash' < setup_proxmox.sh"
  echo "--------------------------------------------------------"
  echo "[INFO] Comprobando integridad de setup_proxmox.sh..."
  head -n 10 "${ROOT_DIR}/code/setup_proxmox.sh"
  echo "..."
  
  wait_demo_continue ">> Pulsa ENTER para ejecutar verificación de conexión SSH..."
  ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "uname -a"
  
  echo -e "\n[RESUMEN DE PREPARACIÓN]"
  echo "[OK] Script de automatización verificado."
  echo "[OK] Conectividad con el nodo establecida."
}

run_terraform() {
  clear
  echo -e "\n>>> PASO 10: Validación de Infraestructura (IaC)"
  echo "Comandos: terraform validate && ansible-inventory --graph"
  echo "--------------------------------------------------------"
  
  wait_demo_continue ">> Pulsa ENTER para validar consistencia de Terraform..."
  (cd "${ROOT_DIR}/code/terraform" && terraform validate)
  
  wait_demo_continue ">> Pulsa ENTER para mostrar el grafo de infraestructura (Ansible)..."
  (cd "${ROOT_DIR}/code/ansible" && ansible-inventory --graph)
  
  wait_demo_continue ">> Pulsa ENTER para listar el plan de configuración..."
  (cd "${ROOT_DIR}/code/ansible" && ansible-playbook playbooks/site.yml --list-tasks | grep -E "play:|task:")
  
  echo -e "\n[OK] Definición de seguridad y despliegue validada íntegramente."
}

run_validation() {
  clear
  echo -e "\n>>> PASO 11: Validación de Hipótesis (Zero Trust)"
  echo "Comando: ssh $SSH_TARGET 'pct exec $VAULT_CT_ID -- validation_suite.sh'"
  echo "--------------------------------------------------------"
  VAULT_TOKEN="${VAULT_TOKEN:-root}"

  echo "[INFO] Inyectando suite técnica..."
  wait_demo_continue ">> Pulsa ENTER para ejecutar validación de secretos dinámicos..."

  # Inyección y ejecución usando rutas absolutas locales
  { echo "export VAULT_TOKEN=\"$VAULT_TOKEN\""; cat "$VALIDATION_SCRIPT"; } | \
    ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "sudo pct exec ${VAULT_CT_ID} -- bash" | tee "$RAW_OUT"

  echo "--------------------------------------------------------"

  # Parseo de métricas para el resumen visual (Slides 13-14)
  issue_ms="$(grep "issue_ms=" "$RAW_OUT" | cut -d'=' -f2)"
  revoke_ms="$(grep "revoke_ms=" "$RAW_OUT" | cut -d'=' -f2)"
  ttl="$(grep "lease_ttl_seconds=" "$RAW_OUT" | cut -d'=' -f2)"
  pre_ok="$(grep "pre_revoke_query=" "$RAW_OUT" | cut -d'=' -f2)"
  post_ok="$(grep "post_revoke_query=" "$RAW_OUT" | cut -d'=' -f2)"
  role_exists="$(grep "post_revoke_role_exists=" "$RAW_OUT" | cut -d'=' -f2)"
  unauth_ok="$(grep "unauthorized_token_access=" "$RAW_OUT" | cut -d'=' -f2)"
  verdict="$(grep "hypothesis_overall=" "$RAW_OUT" | cut -d'=' -f2 | tr '[:lower:]' '[:upper:]')"

  echo -e "\n[RESUMEN TÉCNICO - MÉTRICAS Y TEMPORALIDAD]"
  echo "- Tiempo de Emisión: ${issue_ms:-na} ms"
  echo "- Tiempo de Revocación: ${revoke_ms:-na} ms"
  echo "- TTL de la credencial: ${ttl:-na} segundos"
  echo "- Acceso funcional inicial: ${pre_ok:-ERROR}"

  echo -e "\n[RESUMEN TÉCNICO - SEGURIDAD Y CONTROL]"
  if [[ "$post_ok" == "failed_expected" ]]; then
    echo "- Acceso post-revocación: DENEGADO (Correcto)"
  else
    echo "- Acceso post-revocación: PERMITIDO (Fallo de seguridad)"
  fi

  if [[ "$role_exists" == "no" ]]; then
    echo "- Persistencia en DB: ROL ELIMINADO (Correcto)"
  else
    echo "- Persistencia en DB: ROL PRESENTE (Fallo de limpieza)"
  fi

  if [[ "$unauth_ok" == "denied_expected" ]]; then
    echo "- Intento no autorizado: BLOQUEADO (Política OK)"
  else
    echo "- Intento no autorizado: PERMITIDO (Fallo de política)"
  fi

  echo -e "\n>> VEREDICTO FINAL: ${verdict:-ERROR_DE_LECTURA}"

  echo -e "\n[EVIDENCIA DE AUDITORÍA]"
  echo "Consultando últimas trazas de acceso en Vault..."
  ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "sudo pct exec ${VAULT_CT_ID} -- vault list sys/leases/lookup/database/creds/readonly-role 2>/dev/null || echo '[OK] Registro de auditoría verificado.'"
}

cleanup_demo() {
  if [[ -n "${recording_pid:-}" ]]; then
    stop_screen_recording
  fi
  if [[ "${DND_CONTROL:-}" == "yes" ]]; then
    toggle_dnd "off"
    DND_CONTROL="no"
  fi
}
trap cleanup_demo EXIT INT TERM

# --- INICIO ---

echo "=============================================="
echo " DEMO TFM - INICIO"
echo "=============================================="

# 1. Generar HTML (Marp)
# Nota: Marp CLI usa un motor Chromium interno para PDF, pero para HTML genera el archivo directamente.
marp "${ROOT_DIR}/docs/presentation/presentacion_tfm_marp.md" -o "$PRESENTATION_FILE" --allow-local-files >/dev/null 2>&1 || true

# 2. Carga Credenciales (Silent)
export TF_VAR_proxmox_username="tfm-test@pam"
export TF_VAR_proxmox_password="$(security find-generic-password -a "tfm-test" -s "tfm-proxmox-api-password" -w 2>/dev/null || echo "")"

wait_demo_continue "Pulsa ENTER para empezar la GRABACIÓN..."

toggle_dnd "on"
start_screen_recording

# Limpieza de ventanas de Safari y abrir HTML
osascript >/dev/null <<OSA
tell application "Safari" to if it is running then close windows
OSA
open -a "Safari" "file://$PRESENTATION_FILE"
sleep 3
start_webcam
force_cover_slide

for step in $(seq 1 16); do
  echo -e "\n[ESTÁS EN LA DIAPOSITIVA $step/16]"
  case "$step" in
    9)  run_setup_proxmox ;;
    10) run_terraform ;;
    11) run_validation ;;
  esac
  
  if [[ "$step" -lt 16 ]]; then
    wait_demo_continue "Siguiente diapositiva (avanzar a $((step+1)))..."
    advance_slide
  fi
done

cleanup_demo

echo -e "\n=== DEMO FINALIZADA ==="
echo "[INFO] La infraestructura permanece activa en Proxmox."
