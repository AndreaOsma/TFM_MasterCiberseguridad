#!/usr/bin/env bash
set -euo pipefail

# Terraform apply seguro para Proxmox:
# - No hardcodea credenciales.
# - Pide usuario/password en runtime (password oculta).
# - Opcional: leer/guardar password en Keychain de macOS.
#
# Uso:
#   bash code/terraform/terraform_secure_apply.sh
#
# Variables opcionales:
#   PROXMOX_USERNAME="user@pve"
#   PROXMOX_PASSWORD="..."              # evitar en shell history si puedes
#   SSH_PUBLIC_KEY_PATH="$HOME/.ssh/tfm_proxmox_temp_2026.pub"
#   TF_IN_AUTOMATION=true
#
# Flags opcionales:
#   --keychain-load   intenta leer password desde Keychain
#   --keychain-save   guarda password en Keychain tras pedirla

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TF_DIR="${ROOT_DIR}/code/terraform"
KEYCHAIN_SERVICE="tfm-proxmox-api-password"
KEYCHAIN_ACCOUNT="${PROXMOX_USERNAME:-}"
USE_KEYCHAIN_LOAD="no"
USE_KEYCHAIN_SAVE="no"

for arg in "$@"; do
  case "$arg" in
    --keychain-load) USE_KEYCHAIN_LOAD="yes" ;;
    --keychain-save) USE_KEYCHAIN_SAVE="yes" ;;
    *)
      echo "[ERROR] Flag no reconocido: $arg" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${PROXMOX_USERNAME:-}" ]]; then
  read -r -p "PROXMOX username (ej: tfm-test@pve): " PROXMOX_USERNAME
fi
if [[ -z "${PROXMOX_USERNAME:-}" ]]; then
  echo "[ERROR] PROXMOX_USERNAME vacío." >&2
  exit 1
fi

KEYCHAIN_ACCOUNT="$PROXMOX_USERNAME"

if [[ "$USE_KEYCHAIN_LOAD" == "yes" && -z "${PROXMOX_PASSWORD:-}" ]]; then
  if command -v security >/dev/null 2>&1; then
    set +e
    PROXMOX_PASSWORD="$(security find-generic-password -a "$KEYCHAIN_ACCOUNT" -s "$KEYCHAIN_SERVICE" -w 2>/dev/null)"
    rc=$?
    set -e
    if [[ $rc -ne 0 ]]; then
      PROXMOX_PASSWORD=""
    fi
  fi
fi

if [[ -z "${PROXMOX_PASSWORD:-}" ]]; then
  printf "PROXMOX password: "
  stty -echo
  IFS= read -r PROXMOX_PASSWORD
  stty echo
  printf "\n"
fi
if [[ -z "${PROXMOX_PASSWORD:-}" ]]; then
  echo "[ERROR] PROXMOX_PASSWORD vacío." >&2
  exit 1
fi

if [[ "$USE_KEYCHAIN_SAVE" == "yes" ]]; then
  if ! command -v security >/dev/null 2>&1; then
    echo "[WARN] 'security' no disponible; no se puede guardar en Keychain."
  else
    security add-generic-password -U -a "$KEYCHAIN_ACCOUNT" -s "$KEYCHAIN_SERVICE" -w "$PROXMOX_PASSWORD" >/dev/null
    echo "[INFO] Password guardada en Keychain ($KEYCHAIN_SERVICE / $KEYCHAIN_ACCOUNT)."
  fi
fi

SSH_PUBLIC_KEY_PATH="${SSH_PUBLIC_KEY_PATH:-$HOME/.ssh/tfm_proxmox_temp_2026.pub}"
if [[ ! -f "$SSH_PUBLIC_KEY_PATH" ]]; then
  echo "[ERROR] No existe la clave pública SSH: $SSH_PUBLIC_KEY_PATH" >&2
  exit 1
fi
SSH_PUBLIC_KEY="$(cat "$SSH_PUBLIC_KEY_PATH")"

export TF_VAR_proxmox_username="$PROXMOX_USERNAME"
export TF_VAR_proxmox_password="$PROXMOX_PASSWORD"

cd "$TF_DIR"
terraform init -input=false >/dev/null
terraform apply -auto-approve -input=false -var "ssh_public_key=${SSH_PUBLIC_KEY}"

# Limpieza de secretos del entorno actual del script.
unset TF_VAR_proxmox_password PROXMOX_PASSWORD
