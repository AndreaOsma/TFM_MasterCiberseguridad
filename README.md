# TFM - Gestión dinámica de secretos en entorno on-premise

Repositorio del TFM de Máster en Ciberseguridad centrado en mitigar `Secret Sprawl` con identidad federada, emisión efímera de credenciales y validación reproducible en laboratorio Proxmox.

## Qué incluye este repositorio

- Memoria técnica en LaTeX (`main.tex`, `references.bib`) y PDF generado (`main.pdf`).
- Infraestructura como código para laboratorio (`code/terraform`, `code/ansible`, `code/setup_proxmox.sh`).
- Scripts de validación y demo (`run_demo.sh`, `artifacts/scripts/*`).
- Diagramas y material visual (`diagrams/*`, `artifacts/presentation/presentacion_tfm_marp.pdf`).
- Bundle de release generado para defensa (`artifacts/release/*`).

## Estructura actual

- `main.tex`: memoria principal del TFM.
- `references.bib`: bibliografía.
- `build_pdf.sh`: compilación de la memoria.
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
  - `generate_token.sh`: genera token efímero de demo desde token admin.
  - `proxmox_validation_suite.sh`: validación de hipótesis (A/B/C) en Vault/PostgreSQL.
  - `video_demo_run.sh`: ejecución de validación remota con salida resumida.
  - `validation_campaign.sh`: corridas repetidas con agregación de métricas.
  - `package_release_bundle.sh`: empaquetado de entregable final.
- `artifacts/vault_e2e_test.sh`: prueba e2e de motor de base de datos en Vault.
- `artifacts/presentation/presentacion_tfm_marp.pdf`: presentación usada en defensa.
- `artifacts/release/tfm_defensa_final_20260324_115311*`: snapshot de release generado.
- `docs/requirements/bitacora_sesiones_tfm.md`: bitácora de trabajo.
- `diagrams/*.png` y `diagrams/*.py`: diagramas del TFM y scripts de generación.

## Flujo recomendado para defensa (vídeo)

### 1) Ejecutar demo guiada única

```bash
cd "/Volumes/SSD 2TB/[01] Proyectos/TFM_MasterCiberseguridad"
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
- `VAULT_ADMIN_TOKEN=...`: evita prompt del token admin.

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
bash artifacts/scripts/proxmox_validation_suite.sh
```

Para campaña de métricas:

```bash
RUNS=10 VAULT_TOKEN=... bash artifacts/scripts/validation_campaign.sh
```

## Requisitos de entorno

- macOS (para `open`, `osascript`, Keychain) en estación de operación.
- Acceso SSH al host Proxmox (`tfm-test@proxmox` por defecto).
- Vault operativo en CT `502` con script `/root/proxmox_validation_suite.sh`.
- `rg`, `ssh`, `bash`, `terraform`, `ansible` instalados según flujo.

