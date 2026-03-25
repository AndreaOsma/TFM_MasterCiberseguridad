# Scripts operativos

Esta carpeta agrupa los scripts ejecutables del flujo de validación y verificación.

- `proxmox_validation_suite.sh`: batería de validación de hipótesis en Vault/PostgreSQL.
- `package_release_bundle.sh`: empaquetado de entregable final.

Uso recomendado:
- Para el vídeo del TFM (entrada única): desde la raíz del repo, `./run_demo.sh`.
  - Si estás dentro de `artifacts/scripts/`: `bash ../../run_demo.sh`.
- Ejecutar scripts individuales desde rutas explícitas en `artifacts/scripts/` solo si necesitas depurar.
- Para demo estable (plan B): desde la raíz del repo `ALLOW_FALLBACK=yes ./run_demo.sh` (reutiliza última evidencia válida si falla la conexión remota).

## `proxmox_validation_suite.sh` (validación aislada)

Requiere `VAULT_TOKEN` (token con permisos de lectura para el rol `database/creds/readonly-role`).

Ejemplo:

```bash
VAULT_TOKEN=... bash artifacts/scripts/proxmox_validation_suite.sh
```

Opcionales de entorno:
- `VAULT_ADDR` (por defecto `http://127.0.0.1:8200`)
- `PGHOST` (por defecto `192.168.1.230`)
- `PGPORT` (por defecto `5432`)
- `PGDATABASE` (por defecto `postgres`)

## `package_release_bundle.sh` (entrega)

Embalha artefactos clave para la defensa en un bundle comprimido.

Desde la raíz del repo:

```bash
bash artifacts/scripts/package_release_bundle.sh
```

Opcionales:
- `RELEASE_TAG` (por defecto `tfm_defensa_final`)
- `RELEASE_DIR` (por defecto `artifacts/release`)

Incluye también el último `.mov` grabado en `artifacts/recordings/` (si existe).
