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

## Demo y empaquetado (público)

Este repo incluye un guion único para automatizar la demo (`run_demo.sh`) y un empaquetador (`artifacts/scripts/package_release_bundle.sh`) para recopilar artefactos.

Ejecutar la demo:

```bash
./run_demo.sh
```

Grabar pantalla automáticamente (macOS):

```bash
AUTO_SCREEN_RECORD=yes ./run_demo.sh
```

Empaquetar artefactos:

```bash
bash artifacts/scripts/package_release_bundle.sh
```

Variables opcionales relevantes:
- `AUTO_NEXT=yes`: sin pausas interactivas.
- `SLIDE_CONTROL=no`: no intenta avanzar diapositivas.
- `VAULT_ADMIN_TOKEN=...`: evita prompt del token admin (si no se pasa, el script intenta leerlo desde Keychain y si no lo encuentra lo solicita por consola).
- `AUTO_SCREEN_RECORD=yes`: grabación; `SCREEN_RECORD_AUDIO=yes` (por defecto) graba micrófono; `SCREEN_RECORD_CURSOR=yes` graba el cursor.
- `WINDOW_LAYOUT=yes`: intenta colocar visor a la izquierda y terminal a la derecha (recomendado para terminal “normal” como `Terminal.app` o `iTerm2`).
- `FOCUS_FULLSCREEN_ON_START=yes` (por defecto): pone la app de enfoque en pantalla completa al arrancar; si activas `FOCUS_EDGE_LAYOUT=yes`, el script saldrá de fullscreen para poder dejar el visor/Edge a la izquierda y la app de enfoque a la derecha.
- `FOCUS_EDGE_LAYOUT=yes` (por defecto): mueve Edge a la izquierda y la app de enfoque a la derecha cuando empieza la presentación.
- `FOCUS_REACTIVATE_AFTER_SLIDE=yes` (por defecto): vuelve a poner la app de enfoque al frente justo después de enviar teclas al visor.
- `FOCUS_APP_PROCESS` (por defecto heredado de `FOCUS_APP`): process name para AppleScript/System Events (ajústalo si tu app no se llama así).
- `FOCUS_APP=Cursor`: nombre de la app para AppleScript (por defecto `Cursor`).

