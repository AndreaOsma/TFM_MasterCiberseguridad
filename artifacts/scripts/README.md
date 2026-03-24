# Scripts operativos

Esta carpeta agrupa los scripts ejecutables del flujo de validación y verificación.

- `proxmox_validation_suite.sh`: batería de validación de hipótesis en Vault/PostgreSQL.
- `video_demo_run.sh`: ejecución remota y resumen de resultados.
- `generate_token.sh`: emisión de token efímero desde CT 502.
- `validation_campaign.sh`: corridas repetidas con métricas agregadas (min/mediana/p95/max) y tasa de aserciones.

Uso recomendado:
- Para el vídeo del TFM (entrada única): `bash run_demo.sh`.
- Ejecutar scripts individuales desde rutas explícitas en `artifacts/scripts/` solo si necesitas depurar.
- Para campaña cuantitativa: `RUNS=10 VAULT_TOKEN=... bash artifacts/scripts/validation_campaign.sh`.
- Para demo estable (plan B): `ALLOW_FALLBACK=yes bash run_demo.sh` (reutiliza última evidencia válida si falla la conexión remota).
