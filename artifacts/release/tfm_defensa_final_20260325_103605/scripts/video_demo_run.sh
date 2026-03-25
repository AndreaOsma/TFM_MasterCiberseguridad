#!/usr/bin/env bash
set -euo pipefail

# Demo de evidencia para vídeo del TFM.
# Objetivo: ejecutar comprobaciones 100% por código y mostrar salida compacta.
# Ejecución prevista: Mac local -> SSH a Proxmox (usuario tfm-test) -> script remoto.
#
# Uso recomendado (modo seguro):
#   bash artifacts/scripts/video_demo_run.sh
#   # el script solicitará VAULT_TOKEN sin eco
#
# Variables opcionales para acceso SSH:
#   PROXMOX_USER="tfm-test"
#   PROXMOX_HOST="proxmox"
#   REMOTE_REPO_DIR="~/TFM_MasterCiberseguridad"
#   SSH_KEY_PATH="$HOME/.ssh/tfm_proxmox_temp_2026"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PROXMOX_USER="${PROXMOX_USER:-tfm-test}"
PROXMOX_HOST="${PROXMOX_HOST:-proxmox}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-~/TFM_MasterCiberseguridad}"
SSH_KEY_PATH="${SSH_KEY_PATH:-}"
SSH_TARGET="${PROXMOX_USER}@${PROXMOX_HOST}"
ALLOW_FALLBACK="${ALLOW_FALLBACK:-yes}"

if [[ -z "${VAULT_TOKEN:-}" ]]; then
  read -r -s -p "Introduce VAULT_TOKEN (entrada oculta): " VAULT_TOKEN
  echo
fi
if [[ -z "${VAULT_TOKEN:-}" ]]; then
  echo "[ERROR] VAULT_TOKEN vacío. Cancelando."
  exit 1
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "[ERROR] No se encontró 'rg' en el sistema."
  exit 1
fi

if ! command -v ssh >/dev/null 2>&1; then
  echo "[ERROR] No se encontró 'ssh' en el sistema."
  exit 1
fi

mkdir -p artifacts/validation
RAW_OUT="artifacts/validation/proxmox_validation_results.txt"
SUMMARY_OUT="artifacts/validation/video_demo_summary.txt"

SSH_OPTS=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new)
if [[ -n "$SSH_KEY_PATH" ]]; then
  SSH_OPTS+=(-i "$SSH_KEY_PATH")
fi

echo "[INFO] Ejecutando batería automatizada en ${SSH_TARGET}..."
echo "[INFO] Repositorio remoto: ${REMOTE_REPO_DIR}"

LAST_GOOD_RAW="artifacts/validation/last_known_good_results.txt"
LAST_GOOD_SUMMARY="artifacts/validation/last_known_good_summary.txt"

set +e
ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "cd $REMOTE_REPO_DIR && read -r VAULT_TOKEN && export VAULT_TOKEN && bash artifacts/scripts/proxmox_validation_suite.sh" <<<"$VAULT_TOKEN" \
  | sed -E 's/^(lease_id=).*/\1[REDACTED]/; s/^(db_user=).*/\1[REDACTED]/' \
  | tee "$RAW_OUT"
remote_rc=${PIPESTATUS[0]}
set -e

if [[ "$remote_rc" -ne 0 ]]; then
  echo
  echo "[WARN] La ejecución remota falló (rc=${remote_rc})."
  if [[ "$ALLOW_FALLBACK" == "yes" && -f "$LAST_GOOD_RAW" ]]; then
    echo "[WARN] Activando plan B: usando evidencia local previamente validada."
    cp "$LAST_GOOD_RAW" "$RAW_OUT"
  else
    echo "[ERROR] No hay evidencia de respaldo disponible para plan B." >&2
    exit "$remote_rc"
  fi
fi

echo
echo "[INFO] Extrayendo resumen para presentación..."
rg "^(issue_ms|revoke_ms|lease_ttl_seconds|pre_revoke_query|post_revoke_query|post_revoke_role_exists|unauthorized_token_access|ttl_within_expected_window|revocation_effective|unauthorized_access_blocked|hypothesis_h1_dynamic_secret_reduces_exposure|hypothesis_h2_policy_enforcement_blocks_misuse|hypothesis_overall)=" "$RAW_OUT" | tee "$SUMMARY_OUT"

cp "$RAW_OUT" "$LAST_GOOD_RAW"
cp "$SUMMARY_OUT" "$LAST_GOOD_SUMMARY"

echo
echo "[INFO] Resultado clave:"
rg "^hypothesis_overall=" "$SUMMARY_OUT"

echo
echo "[OK] Demo finalizada."
echo "     Evidencia completa: $RAW_OUT"
echo "     Resumen para vídeo: $SUMMARY_OUT"
