#!/usr/bin/env bash
set -euo pipefail

# Empaqueta un bundle final de defensa con artefactos clave.
#
# Uso:
#   bash artifacts/scripts/package_release_bundle.sh
#
# Variables opcionales:
#   RELEASE_TAG=tfm_defensa_final
#   RELEASE_DIR=artifacts/release

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RELEASE_TAG="${RELEASE_TAG:-tfm_defensa_final}"
RELEASE_DIR="${RELEASE_DIR:-artifacts/release}"
STAMP="$(date +%Y%m%d_%H%M%S)"
BUNDLE_DIR="${RELEASE_DIR}/${RELEASE_TAG}_${STAMP}"

mkdir -p "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR"/{memoria,presentacion,evidencias,scripts,meta,video}

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
    echo "[OK] Copiado: $src"
  else
    echo "[WARN] No encontrado: $src"
  fi
}

# Memoria
copy_if_exists "main.tex" "$BUNDLE_DIR/memoria/main.tex"
copy_if_exists "main.pdf" "$BUNDLE_DIR/memoria/main.pdf"
copy_if_exists "references.bib" "$BUNDLE_DIR/memoria/references.bib"

# Presentacion y guion
copy_if_exists "docs/presentation/presentacion_tfm_marp.md" "$BUNDLE_DIR/presentacion/presentacion_tfm_marp.md"
copy_if_exists "artifacts/presentation/presentacion_tfm_marp.pdf" "$BUNDLE_DIR/presentacion/presentacion_tfm_marp.pdf"
copy_if_exists "docs/presentation/guion_defensa_12_15min.md" "$BUNDLE_DIR/presentacion/guion_defensa_12_15min.md"

# Evidencias disponibles
if [[ -d "artifacts/validation" ]]; then
  cp -R "artifacts/validation" "$BUNDLE_DIR/evidencias/"
  echo "[OK] Copiado directorio: artifacts/validation"
else
  echo "[WARN] No existe artifacts/validation (se creará al ejecutar demos/campañas)."
fi

# Scripts de reproduccion
copy_if_exists "run_demo.sh" "$BUNDLE_DIR/scripts/run_demo.sh"
copy_if_exists "artifacts/scripts/proxmox_validation_suite.sh" "$BUNDLE_DIR/scripts/proxmox_validation_suite.sh"

# Vídeo de la demo (opcional)
if [[ -d "artifacts/recordings" ]]; then
  latest_link="artifacts/recordings/latest_video_demo.mov"
  last_path_file="artifacts/recordings/last_video_demo_path.txt"

  video_src=""
  if [[ -L "$latest_link" || -f "$latest_link" ]]; then
    video_src="$latest_link"
  elif [[ -f "$last_path_file" ]]; then
    video_src="$(cat "$last_path_file" 2>/dev/null | tr -d '\n' || true)"
  fi

  if [[ -n "${video_src:-}" && -f "$video_src" ]]; then
    cp "$video_src" "$BUNDLE_DIR/video/$(basename "$video_src")"
    echo "[OK] Copiado vídeo de demo: $video_src"
  else
    echo "[WARN] No existe vídeo grabado (latest_video_demo.mov) para incluir en el bundle."
  fi
fi

# Metadatos minimos de release
cat > "$BUNDLE_DIR/meta/release_manifest.txt" <<EOF
release_tag=${RELEASE_TAG}
generated_at=${STAMP}
bundle_path=${BUNDLE_DIR}
git_head=$(git rev-parse --short HEAD 2>/dev/null || echo "na")
EOF

cat > "$BUNDLE_DIR/meta/checklist_entrega.md" <<'EOF'
# Checklist de entrega TFM

- [ ] Memoria final revisada (`main.pdf`) sin incoherencias internas.
- [ ] Presentación de defensa final (`presentacion_tfm_marp.pdf` o `.md`).
- [ ] Guion oral 12-15 min con argumentos y límites claros.
- [ ] Evidencia técnica incluida (`artifacts/validation/*`) y verificable.
- [ ] Scripts de reproducción incluidos y ejecutables.
- [ ] Demo validada con plan B (`ALLOW_FALLBACK=yes`).
EOF

# Empaquetado comprimido
tar -czf "${BUNDLE_DIR}.tar.gz" -C "$RELEASE_DIR" "$(basename "$BUNDLE_DIR")"

echo "[OK] Bundle generado: $BUNDLE_DIR"
echo "[OK] Bundle comprimido: ${BUNDLE_DIR}.tar.gz"
