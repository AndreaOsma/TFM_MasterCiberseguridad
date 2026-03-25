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

## Flujo recomendado para defensa (vídeo)

### 1) Ejecutar demo guiada única

```bash
cd /ruta/al/repositorio/TFM_MasterCiberseguridad
./run_demo.sh
```

`run_demo.sh` abre la presentación, avanza diapositivas por pasos y ejecuta la validación técnica en el paso configurado (`VALIDATION_STEP`, por defecto 11).

### 2) Parámetros útiles

```bash
TOTAL_STEPS=17 VALIDATION_STEP=11 PRESENTATION_APP="Microsoft Edge" ./run_demo.sh
```

Opcionales:

- `AUTO_NEXT=yes`: modo automático sin pausas interactivas.
- `SLIDE_CONTROL=no`: desactiva avance de diapositivas por script.
- `SLIDE_KEY=right|space`: tecla usada para avanzar.
- `VAULT_ADMIN_TOKEN=...`: evita prompt (si no se pasa, `run_demo.sh` intenta leerlo desde Keychain y si no lo encuentra lo solicita por consola).
- `AUTO_SCREEN_RECORD=yes` (por defecto `no`): graba automáticamente la pantalla y guarda un `.mov` en `artifacts/recordings/`.
- `SCREEN_RECORD_AUDIO=yes` (por defecto): incluye audio de micrófono.
- `SCREEN_RECORD_CURSOR=yes` (por defecto): graba el cursor en el vídeo.
- `SCREEN_RECORD_AUDIO_DEVICE_ID=` opcional: si tienes varios micrófonos, usa `-G<id>` para elegir el input correcto.
- `package_release_bundle.sh` incluye el vídeo grabado de esta ejecución (usando `artifacts/recordings/latest_video_demo.mov`).
- `SCREEN_RECORD_CLEAN_BEFORE=yes` (por defecto): limpia los punteros `latest` antes de grabar para no arrastrar un vídeo viejo si falla la captura.
- `SCREEN_RECORD_STOP_TIMEOUT_SEC=4` (por defecto): timeout máximo al parar `screencapture`.
- `SCREEN_RECORD_VIDEO_MARKER=no` (por defecto): muestra notificaciones visibles alrededor de la validación (opcional, por si quieres sincronía en el timeline).

## Despliegue del laboratorio (IaC)

### 1) Preparación Proxmox

```bash
chmod +x code/setup_proxmox.sh
./code/setup_proxmox.sh
```

### 2) Terraform

```bash
cd code/terraform
terraform init
terraform apply
```

### 3) Ansible

```bash
cd ../ansible
chmod +x scripts/render_inventory_from_tf.sh
./scripts/render_inventory_from_tf.sh
ansible-playbook playbooks/site.yml
```

## Validación técnica aislada

Si no quieres correr toda la demo guiada:

```bash
VAULT_TOKEN=... bash artifacts/scripts/proxmox_validation_suite.sh
```

## Requisitos de entorno

- macOS (para `open`, `osascript`, Keychain) en estación de operación.
- Permisos de Accesibilidad/Automatización en macOS para que `osascript` pueda enviar eventos de teclado al visor de PDF.
- Permisos de "Grabación de pantalla" (Screen Recording) en macOS para que `screencapture -v` funcione (y micrófono si usas `SCREEN_RECORD_AUDIO=yes`).
- Acceso SSH al host Proxmox (`tfm-test@proxmox` por defecto).
- Vault operativo en CT `502` con script `/root/proxmox_validation_suite.sh`.
- Dentro de CT `502` deben estar disponibles `vault`, `psql` y `python3` para que la validación aislada pueda ejecutarse.
- `rg`, `ssh`, `bash`, `terraform`, `ansible` instalados según flujo.

