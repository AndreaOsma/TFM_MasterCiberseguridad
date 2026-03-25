# Scripts operativos

Esta carpeta agrupa los scripts ejecutables del flujo de validación y verificación.

- `proxmox_validation_suite.sh`: batería de validación de hipótesis en Vault/PostgreSQL.
- `package_release_bundle.sh`: empaquetado de entregable final.

Las instrucciones detalladas de ejecución (incluyendo grabación de pantalla y empaquetado) están en `.private/` (no versionado).

`package_release_bundle.sh` empaqueta artefactos clave para defensa e intenta incluir el vídeo generado por `run_demo.sh` (si existe).
