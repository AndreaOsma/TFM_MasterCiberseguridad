#!/usr/bin/env bash
set -euo pipefail

# Compila la memoria y exporta un PDF con nombre de entrega.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

OUTPUT_NAME="${1:-TFM_Andrea_Osma_Rafael_Secret_Sprawl.pdf}"

latexmk -pdf -interaction=nonstopmode -halt-on-error "main.tex"
cp -f "main.pdf" "$OUTPUT_NAME"

echo "[OK] PDF generado: $OUTPUT_NAME"
