# TFM - Máster en Ciberseguridad - Campus de ciberseguridad de la ENIIT

Este repositorio contiene la **Infraestructura como Código (IaC)** para el despliegue del laboratorio experimental del Trabajo de Final de Máster, así como los fuentes de la memoria técnica en LaTeX.



## Estructura del Proyecto



* **code/terraform/**: Definición de recursos en Proxmox (LXC y VMs).

* **code/ansible/**: Playbooks para la configuración de servicios (Vault, K3s, PostgreSQL).

* **setup_proxmox.sh**: Script de inicialización y descarga de assets en el nodo Proxmox.

* **main.tex**: Documento principal de la memoria técnica.

* **references.bib**: Gestión de bibliografía.



## Despliegue Rápido



### 1. Preparación del Entorno

Ejecutar el script de configuración en el host Proxmox para instalar dependencias y la imagen base de Debian 12:

```bash

chmod +x code/setup_proxmox.sh

./code/setup_proxmox.sh

```



### 2. Aprovisionamiento de Infraestructura

Acceder al directorio de Terraform para levantar el laboratorio:



```bash

cd code/terraform

terraform init

terraform apply

```



## Stack Tecnológico

* **Hipervisor**: Proxmox VE 8.4 (Almacenamiento optimizado en NVMe).

* **Orquestación**: Terraform.

* **Configuración**: Ansible.

* **Documentación**: LaTeX.

