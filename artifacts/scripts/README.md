# Scripts operativos

Esta carpeta agrupa los scripts ejecutables del flujo de validación y verificación.

- `proxmox_validation_suite.sh`: batería de validación de hipótesis en Vault/PostgreSQL.
- `package_release_bundle.sh`: empaquetado de entregable final.

`package_release_bundle.sh` empaqueta artefactos clave y, si existe una grabación generada por `run_demo.sh`, la intenta incluir en el bundle.
