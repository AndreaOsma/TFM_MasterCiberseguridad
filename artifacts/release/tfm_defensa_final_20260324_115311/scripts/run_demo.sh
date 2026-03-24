#!/usr/bin/env bash
set -euo pipefail

# Ejecución integrada de presentación y validación técnica.
# Flujo:
# 1) Generación de token temporal (solicita VAULT_ADMIN_TOKEN si no existe en entorno/llavero).
# 2) Ejecución de validación técnica para demo y defensa.
#
# Uso:
#   bash run_demo.sh
#
# Variables opcionales:
#   PROXMOX_USER=tfm-test
#   PROXMOX_HOST=proxmox
#   SSH_KEY_PATH=$HOME/.ssh/tfm_proxmox_temp_2026
#   REMOTE_REPO_DIR=~/TFM_MasterCiberseguridad
#   VAULT_CT_ID=502
#   VAULT_ADDR=http://127.0.0.1:8200
#   DEMO_POLICY=readonly-db
#   DEMO_TTL=15m
#   DEMO_MAX_TTL=30m
#   PRESENTATION_APP="Microsoft Edge"
#   TOTAL_STEPS=17
#   DEMO_STEP=11
#   ALLOW_FALLBACK=yes|no

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

TOKEN="$(bash artifacts/scripts/generate_token.sh)"
ALLOW_FALLBACK="${ALLOW_FALLBACK:-yes}"
VAULT_TOKEN="$TOKEN" ALLOW_FALLBACK="$ALLOW_FALLBACK" bash artifacts/scripts/video_demo_run.sh
unset TOKEN VAULT_TOKEN
