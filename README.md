# TFM - Máster en Ciberseguridad - Campus de ciberseguridad de la ENIIT

Este repositorio contiene la **Infraestructura como Código (IaC)** para el despliegue del laboratorio experimental del Trabajo de Final de Máster, así como los fuentes de la memoria técnica en LaTeX.



## Estructura del Proyecto

* **code/terraform/**: Definición de recursos en Proxmox (LXC y VMs).
* **code/ansible/**: Playbooks para la configuración de servicios (Vault, K3s, PostgreSQL).
* **code/setup_proxmox.sh**: Script de inicialización y descarga de assets en el nodo Proxmox.
* **docs/requirements/**: Requisitos de entrega y checklist de presentación.
* **docs/presentation/**: Presentación Marp editable.
* **docs/blog/**: Entrada de blog editable.
* **artifacts/**: Salidas renderizadas y entregables generados (PDF/HTML, etc.).
* **main.tex**: Documento principal de la memoria técnica.
* **references.bib**: Gestión de bibliografía.



## Despliegue Rápido



### 1. Preparación del Entorno

Ejecutar el script de configuración en el host Proxmox para instalar dependencias y la imagen base Cloud-Init de Debian 12 (VM K3s):

```bash

chmod +x code/setup_proxmox.sh

./code/setup_proxmox.sh

```



### 2. Aprovisionamiento de Infraestructura

Acceder al directorio de Terraform para levantar el laboratorio:

> Nota: el endpoint por defecto de Proxmox se define como `https://proxmox:8006/` porque el acceso al host en este entorno se realiza mediante DNS de Tailscale.



```bash

cd code/terraform

terraform init

terraform apply

```

### 3. Configuración de Servicios con Ansible

```bash

cd ../ansible

chmod +x scripts/render_inventory_from_tf.sh

./scripts/render_inventory_from_tf.sh

ansible-playbook playbooks/site.yml

```



## Stack Tecnológico

* **Hipervisor**: Proxmox VE 8.4 (Almacenamiento optimizado en NVMe).

* **Orquestación**: Terraform.

* **Configuración**: Ansible.

* **Documentación**: LaTeX.

