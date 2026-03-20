#!/bin/bash
set -e

echo "[*] 1. Instalando dependencias base y repositorios..."
apt-get update && apt-get install -y gnupg software-properties-common curl wget sshpass

# Añadir repositorio de HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

echo "[*] 2. Instalando Terraform y Ansible..."
apt-get update
apt-get install -y terraform ansible

echo "[*] 3. Descargando imagen Debian 12 Cloud-Init a local:iso..."
ISO_DIR="/var/lib/vz/template/iso"
DEBIAN_IMG="debian-12-genericcloud-amd64.img"
# URL oficial de la imagen genérica de Cloud para Debian 12
URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"

if [ ! -f "$ISO_DIR/$DEBIAN_IMG" ]; then
    # Descargamos como qcow2 y lo renombramos a .img para el Terraform
    wget -O "$ISO_DIR/$DEBIAN_IMG" "$URL"
    echo "[+] Imagen descargada correctamente en $ISO_DIR/$DEBIAN_IMG"
else
    echo "[!] La imagen ya existe, saltando descarga."
fi

echo "[*] 4. Verificando instalaciones..."
terraform -v
ansible --version
ls -lh "$ISO_DIR/$DEBIAN_IMG"

echo -e "\n[OK] Entorno listo."
