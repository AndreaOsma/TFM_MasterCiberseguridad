#!/bin/bash
set -euo pipefail

# Prepara el host Proxmox con herramientas IaC y plantilla cloud.
echo "[*] 1. Instalando dependencias base y repositorios..."
apt-get update && apt-get install -y gnupg software-properties-common lsb-release ca-certificates curl wget

# Añadir repositorio de HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

echo "[*] 2. Instalando Terraform y Ansible..."
apt-get update
apt-get install -y terraform ansible

echo "[*] 3. Descargando imagen Debian 12 Cloud-Init a local:iso..."
ISO_DIR="/var/lib/vz/template/iso"
DEBIAN_QCOW2="debian-12-genericcloud-amd64.qcow2"
DEBIAN_IMG="debian-12-genericcloud-amd64.img"
# URL oficial de la imagen genérica de Cloud para Debian 12
URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
SUMS_URL="https://cloud.debian.org/images/cloud/bookworm/latest/SHA512SUMS"

mkdir -p "$ISO_DIR"
if [ ! -w "$ISO_DIR" ]; then
    echo "[ERROR] No se puede escribir en $ISO_DIR. Ejecuta el script con permisos adecuados."
    exit 1
fi

if [ ! -f "$ISO_DIR/$DEBIAN_QCOW2" ]; then
    # Guardamos el archivo original qcow2 para verificar su huella.
    wget -O "$ISO_DIR/$DEBIAN_QCOW2" "$URL"
    if [ ! -s "$ISO_DIR/$DEBIAN_QCOW2" ]; then
        echo "[ERROR] La descarga de $DEBIAN_QCOW2 ha fallado o está vacía."
        exit 1
    fi
    echo "[+] Imagen descargada correctamente en $ISO_DIR/$DEBIAN_QCOW2"
else
    echo "[!] La imagen qcow2 ya existe, saltando descarga."
fi

echo "[*] 3b. Verificando checksum SHA512 de la imagen..."
TMP_SUMS="$(mktemp)"
wget -q -O "$TMP_SUMS" "$SUMS_URL"
EXPECTED_SHA512="$(awk '/debian-12-genericcloud-amd64.qcow2$/ {print $1}' "$TMP_SUMS")"
ACTUAL_SHA512="$(sha512sum "$ISO_DIR/$DEBIAN_QCOW2" | awk '{print $1}')"
rm -f "$TMP_SUMS"

if [ -z "$EXPECTED_SHA512" ] || [ "$EXPECTED_SHA512" != "$ACTUAL_SHA512" ]; then
    echo "[ERROR] Verificación SHA512 fallida para $DEBIAN_QCOW2"
    exit 1
fi
echo "[+] Checksum SHA512 verificado correctamente."

if [ ! -f "$ISO_DIR/$DEBIAN_IMG" ]; then
    # Terraform usa este nombre en la plantilla Cloud-Init del laboratorio.
    cp "$ISO_DIR/$DEBIAN_QCOW2" "$ISO_DIR/$DEBIAN_IMG"
fi

echo "[*] 4. Verificando instalaciones..."
terraform -v
ansible --version
ls -lh "$ISO_DIR/$DEBIAN_IMG"

echo -e "\n[OK] Entorno listo."
