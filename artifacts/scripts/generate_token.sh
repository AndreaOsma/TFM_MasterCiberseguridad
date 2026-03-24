#!/usr/bin/env bash
set -euo pipefail

# Genera un token efimero de demo en Vault desde Mac local:
# Mac -> SSH proxmox -> pct exec 502 -> vault token create
#
# Uso:
#   bash artifacts/scripts/generate_token.sh
#
# Variables opcionales:
#   PROXMOX_HOST=proxmox
#   PROXMOX_USER=tfm-test
#   SSH_KEY_PATH=$HOME/.ssh/tfm_proxmox_temp_2026
#   VAULT_CT_ID=502
#   VAULT_ADDR=http://127.0.0.1:8200
#   DEMO_POLICY=readonly-db
#   DEMO_TTL=15m
#   DEMO_MAX_TTL=30m
#   KEYCHAIN_SERVICE=tfm-vault-admin-token
#   KEYCHAIN_ACCOUNT=proxmox-vault-admin
#   SAVE_TO_KEYCHAIN=yes|no
#
# Salida:
#   Imprime SOLO el token efimero por stdout (sin texto adicional).

PROXMOX_HOST="${PROXMOX_HOST:-proxmox}"
PROXMOX_USER="${PROXMOX_USER:-tfm-test}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/tfm_proxmox_temp_2026}"
VAULT_CT_ID="${VAULT_CT_ID:-502}"
VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
DEMO_POLICY="${DEMO_POLICY:-readonly-db}"
DEMO_TTL="${DEMO_TTL:-15m}"
DEMO_MAX_TTL="${DEMO_MAX_TTL:-30m}"
KEYCHAIN_SERVICE="${KEYCHAIN_SERVICE:-tfm-vault-admin-token}"
KEYCHAIN_ACCOUNT="${KEYCHAIN_ACCOUNT:-proxmox-vault-admin}"
SAVE_TO_KEYCHAIN="${SAVE_TO_KEYCHAIN:-yes}"

if ! command -v ssh >/dev/null 2>&1; then
  echo "[ERROR] ssh no está disponible." >&2
  exit 1
fi

if [[ ! -f "$SSH_KEY_PATH" ]]; then
  echo "[ERROR] No existe la clave SSH: $SSH_KEY_PATH" >&2
  exit 1
fi

# 1) Intentar cargar desde Keychain (macOS), si existe.
if [[ -z "${VAULT_ADMIN_TOKEN:-}" ]] && command -v security >/dev/null 2>&1; then
  set +e
  VAULT_ADMIN_TOKEN="$(security find-generic-password -a "$KEYCHAIN_ACCOUNT" -s "$KEYCHAIN_SERVICE" -w 2>/dev/null)"
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    VAULT_ADMIN_TOKEN=""
  fi
fi

# 2) Si no estaba en Keychain/entorno, pedirlo de forma oculta.
if [[ -z "${VAULT_ADMIN_TOKEN:-}" ]]; then
  printf "VAULT_ADMIN_TOKEN: " >&2
  stty -echo
  IFS= read -r VAULT_ADMIN_TOKEN
  stty echo
  printf "\n" >&2
  TOKEN_FROM_PROMPT="yes"
else
  TOKEN_FROM_PROMPT="no"
fi

if [[ -z "${VAULT_ADMIN_TOKEN:-}" ]]; then
  echo "[ERROR] VAULT_ADMIN_TOKEN vacío." >&2
  exit 1
fi

# 3) Guardado opcional en Keychain para siguientes ejecuciones.
if [[ "$SAVE_TO_KEYCHAIN" == "yes" && "$TOKEN_FROM_PROMPT" == "yes" ]]; then
  if command -v security >/dev/null 2>&1; then
    security add-generic-password -U -a "$KEYCHAIN_ACCOUNT" -s "$KEYCHAIN_SERVICE" -w "$VAULT_ADMIN_TOKEN" >/dev/null
  else
    echo "[WARN] No se pudo guardar en Keychain: comando 'security' no disponible." >&2
  fi
fi

SSH_OPTS=(-i "$SSH_KEY_PATH" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new)
SSH_TARGET="${PROXMOX_USER}@${PROXMOX_HOST}"

token="$(
  ssh "${SSH_OPTS[@]}" "$SSH_TARGET" \
    "sudo -n /usr/sbin/pct exec ${VAULT_CT_ID} -- sh -lc 'export VAULT_ADDR=\"${VAULT_ADDR}\"; export VAULT_TOKEN=\"${VAULT_ADMIN_TOKEN}\"; vault token create -policy=\"${DEMO_POLICY}\" -ttl=\"${DEMO_TTL}\" -explicit-max-ttl=\"${DEMO_MAX_TTL}\" -field=token'" \
    2>/dev/null
)"

if [[ -z "${token:-}" ]]; then
  echo "[ERROR] No se pudo generar token efímero (salida vacía)." >&2
  exit 1
fi

printf "%s\n" "$token"
