# Scripts operativos

Esta carpeta agrupa los scripts ejecutables del flujo de validación y verificación.

- `proxmox_validation_suite.sh`: batería de validación de hipótesis en Vault/PostgreSQL.
- `package_release_bundle.sh`: empaquetado de entregable final.

`package_release_bundle.sh` empaqueta artefactos clave y, si existe una grabación generada por `run_demo.sh`, la intenta incluir en el bundle.

Por defecto usa `BUNDLE_MINIMAL=no`, que incluye el bundle “OBLIGATORIO”:
- papel (`main.pdf`/`main.tex`)
- presentación (PDF y `.md`)
- entrada de blog (`docs/blog/entrada_blog_tfm.md`)
- código y scripts necesarios (`code/` + `run_demo.sh` + `proxmox_validation_suite.sh`)
- vídeo si existe (<= 5 minutos)

Si quieres el bundle minimal recortado, usa `BUNDLE_MINIMAL=yes` (sin presentación PDF, sin vídeo y sin evidencias).
