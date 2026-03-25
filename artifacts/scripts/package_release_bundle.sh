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
#   BUNDLE_MINIMAL=yes|no  (por defecto: no)
#     - yes: bundle minimal (sin presentación PDF, sin vídeo y sin evidencias).
#     - no : bundle “OBLIGATORIO” (paper + presentación + blog + código + vídeo si existe).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RELEASE_TAG="${RELEASE_TAG:-tfm_defensa_final}"
RELEASE_DIR="${RELEASE_DIR:-artifacts/release}"
DEFAULT_BUNDLE_MINIMAL="no"
BUNDLE_MINIMAL="${BUNDLE_MINIMAL:-$DEFAULT_BUNDLE_MINIMAL}"
STAMP="$(date +%Y%m%d_%H%M%S)"
BUNDLE_DIR="${RELEASE_DIR}/${RELEASE_TAG}_${STAMP}"

mkdir -p "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR"/{memoria,presentacion,evidencias,scripts,meta,video,blog,codigo}

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

if [[ "$BUNDLE_MINIMAL" == "yes" ]]; then
  # Bundle minimal: copia el repo excluyendo outputs y binarios.
  # Mantiene scripts de `artifacts/scripts` porque es código útil para validar.
  if ! command -v rsync >/dev/null 2>&1; then
    echo "[ERROR] 'rsync' no está disponible en este entorno." >&2
    exit 1
  fi

  # Copiamos todo desde la raíz del repo al bundle.
  # Importante: el propio BUNDLE_DIR está dentro de artifacts/release/, que se excluye.
  rsync -a --prune-empty-dirs \
    --exclude='.git/**' \
    --exclude='.private/**' \
    --exclude='*.code-workspace' \
    --exclude='main.pdf' \
    --exclude='artifacts/presentation/**' \
    --exclude='artifacts/recordings/**' \
    --exclude='artifacts/validation/**' \
    --exclude='artifacts/release/**' \
    --exclude='*.mov' \
    --exclude='*.zip' \
    ./ "$BUNDLE_DIR"/

  # Asegura que existan los directorios de metadatos aunque rsync los haya ignorado.
  mkdir -p "$BUNDLE_DIR/meta"
else
  # Memoria (bundle completo)
  copy_if_exists "main.tex" "$BUNDLE_DIR/memoria/main.tex"
  copy_if_exists "main.pdf" "$BUNDLE_DIR/memoria/main.pdf"
  copy_if_exists "references.bib" "$BUNDLE_DIR/memoria/references.bib"

  # Presentacion y guion
  copy_if_exists "docs/presentation/presentacion_tfm_marp.md" "$BUNDLE_DIR/presentacion/presentacion_tfm_marp.md"
  copy_if_exists "artifacts/presentation/presentacion_tfm_marp.pdf" "$BUNDLE_DIR/presentacion/presentacion_tfm_marp.pdf"
  copy_if_exists "docs/presentation/guion_defensa_12_15min.md" "$BUNDLE_DIR/presentacion/guion_defensa_12_15min.md"

  # Blog (entrada en formato simple)
  copy_if_exists "docs/blog/entrada_blog_tfm.md" "$BUNDLE_DIR/blog/entrada_blog_tfm.md"

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

  # Código necesario para implementar y demostrar (IaC + bootstrap del laboratorio)
  if [[ -d "code/terraform" ]]; then
    cp -R "code/terraform" "$BUNDLE_DIR/codigo/"
  fi
  if [[ -d "code/ansible" ]]; then
    cp -R "code/ansible" "$BUNDLE_DIR/codigo/"
  fi
  copy_if_exists "code/setup_proxmox.sh" "$BUNDLE_DIR/codigo/setup_proxmox.sh"

  # Vídeo de la demo (opcional)
  if [[ -d "artifacts/recordings" ]]; then
    latest_link="artifacts/recordings/latest_video_demo.mov"
    last_path_file="artifacts/recordings/last_video_demo_path.txt"

    # Preferimos la ruta exacta guardada por `run_demo.sh` (evita copiar el symlink).
    video_src=""
    if [[ -f "$last_path_file" ]]; then
      video_src="$(cat "$last_path_file" 2>/dev/null | tr -d '\n' || true)"
    fi
    if [[ -z "${video_src:-}" || ! -f "$video_src" ]]; then
      # Fallback: si existe el fichero/symlink "latest", intenta usarlo.
      if [[ -L "$latest_link" ]]; then
        video_src="$(readlink "$latest_link" 2>/dev/null || true)"
      elif [[ -f "$latest_link" ]]; then
        video_src="$latest_link"
      fi
    fi

    if [[ -n "${video_src:-}" && -f "$video_src" ]]; then
      cp -L "$video_src" "$BUNDLE_DIR/video/$(basename "$video_src")"
      echo "[OK] Copiado vídeo de demo: $video_src"
    else
      echo "[WARN] No existe vídeo grabado (latest_video_demo.mov) para incluir en el bundle."
    fi
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
- [ ] Entrada de blog (`blog/entrada_blog_tfm.md`).
- [ ] Guion oral 12-15 min con argumentos y límites claros.
- [ ] Evidencia técnica incluida (`artifacts/validation/*`) y verificable.
- [ ] Scripts de reproducción incluidos y ejecutables (`scripts/run_demo.sh`, etc.).
- [ ] Código necesario para implementar y demostrar (`codigo/` y scripts relacionados).
- [ ] Demo validada con plan B (`ALLOW_FALLBACK=yes`).
- [ ] Vídeo de demostración <= 5 minutos (si aplica).
EOF

# Empaquetado comprimido
# Se crea un .zip para facilitar la entrega/descarga en plataformas diversas.
ZIP_PATH="${BUNDLE_DIR}.zip"
(
  cd "$RELEASE_DIR"
  zip -r -q "$(basename "$ZIP_PATH")" "$(basename "$BUNDLE_DIR")"
)

echo "[OK] Bundle generado: $BUNDLE_DIR"
echo "[OK] Bundle comprimido: ${BUNDLE_DIR}.zip"
