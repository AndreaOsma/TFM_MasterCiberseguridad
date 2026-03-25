# TFM - Gestión dinámica de secretos en entorno on-premise

Repositorio del TFM de Máster en Ciberseguridad centrado en mitigar `Secret Sprawl` con identidad federada, emisión efímera de credenciales y validación reproducible en laboratorio Proxmox.

## Qué incluye este repositorio

- Memoria técnica en LaTeX (`main.tex`, `references.bib`) y PDF generado (`main.pdf`).
- Infraestructura como código para laboratorio (`code/terraform`, `code/ansible`, `code/setup_proxmox.sh`).
- Scripts de validación y demo (`run_demo.sh` y `artifacts/scripts/proxmox_validation_suite.sh`).
- Diagramas y material visual (`diagrams/*`, `artifacts/presentation/presentacion_tfm_marp.pdf`).
- Bundle de release generado para defensa (`artifacts/release/*`).

## Estructura actual

- `main.tex`: memoria principal del TFM.
- `references.bib`: bibliografía.
- `run_demo.sh`: guion ejecutable de demo para vídeo (avance de diapositivas + validación técnica).
- `code/setup_proxmox.sh`: preparación base del host Proxmox.
- `code/terraform/`
  - `main.tf`, `variables.tf`, `outputs.tf`, `vault_bootstrap.tf`
  - `terraform_secure_apply.sh`
- `code/ansible/`
  - `ansible.cfg`, `group_vars/all.yml`, `inventories/lab/hosts.yml`
  - `playbooks/site.yml`, `lxc_gitea.yml`, `lxc_vault.yml`, `lxc_postgres.yml`, `vm_k3s.yml`
  - `scripts/render_inventory_from_tf.sh`
- `artifacts/scripts/`
  - `proxmox_validation_suite.sh`: validación de hipótesis (A/B/C) en Vault/PostgreSQL.
  - `package_release_bundle.sh`: empaquetado de entregable final.
- `artifacts/presentation/presentacion_tfm_marp.pdf`: presentación usada en defensa.
- `artifacts/release/tfm_defensa_final_20260324_115311*`: snapshot de release generado.
- `docs/requirements/bitacora_sesiones_tfm.md`: bitácora de trabajo.
- `diagrams/*.png` y `diagrams/*.py`: diagramas del TFM y scripts de generación.

## Compilación de la memoria (LaTeX)

Genera `main.pdf` a partir de `main.tex`.

Ejemplos (según tu herramienta LaTeX instalada):

```bash
latexmk -pdf -interaction=nonstopmode main.tex
```

Si no usas `latexmk`, sigue tu flujo estándar de LaTeX (compilación + bib/biber según configuración).

## Instrucciones operativas (privadas)

Las instrucciones detalladas para ejecutar `run_demo.sh`, capturar vídeo y generar el bundle de defensa están en `.private/` (no versionado).

