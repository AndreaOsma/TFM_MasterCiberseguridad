#!/usr/bin/env bash
set -euo pipefail

TF_DIR="${1:-../terraform}"
OUT_FILE="${2:-inventories/lab/hosts.yml}"
SSH_KEY="${3:-~/.ssh/tfm_proxmox_temp}"

cd "$(dirname "$0")/.."

tf_output() {
  terraform -chdir="$TF_DIR" output -raw "$1" 2>/dev/null || true
}

gitea_ip="$(tf_output lxc_gitea_ip)"
vault_ip="$(tf_output lxc_vault_ip)"
postgres_ip="$(tf_output lxc_postgres_ip)"
k3s_ip="$(tf_output vm_k3s_ip)"

cat > "$OUT_FILE" <<EOF
all:
  vars:
    ansible_ssh_private_key_file: $SSH_KEY
  children:
    gitea_runner:
      hosts:
        gitea:
          ansible_host: ${gitea_ip:-192.168.1.211/24}
          ansible_user: root
    vault_servers:
      hosts:
        vault:
          ansible_host: ${vault_ip:-192.168.1.220/24}
          ansible_user: root
    postgres_servers:
      hosts:
        postgres:
          ansible_host: ${postgres_ip:-192.168.1.230/24}
          ansible_user: root
    k3s_servers:
      hosts:
        k3s:
          ansible_host: ${k3s_ip:-192.168.1.240/24}
          ansible_user: debian
EOF

# Remove CIDR suffix if present (e.g. /24, /32).
sed -E -i.bak 's#/([0-9]{1,2})##g' "$OUT_FILE" && rm -f "$OUT_FILE.bak"
echo "[OK] Inventory generated at: $OUT_FILE"
