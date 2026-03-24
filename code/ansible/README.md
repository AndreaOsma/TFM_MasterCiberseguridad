# Aprovisionamiento Ansible del laboratorio TFM

Este directorio configura cada nodo del laboratorio creado con Terraform:

- `gitea-runner` (LXC)
- `vault-server` (LXC)
- `postgres-db` (LXC)
- `k3s-cluster` (VM)

## Estructura

- `ansible.cfg`: parámetros comunes de ejecución
- `inventories/lab/hosts.yml`: inventario estático (IP por defecto)
- `playbooks/site.yml`: orquesta todos los playbooks por nodo
- `playbooks/lxc_gitea.yml`: configuración base del nodo Gitea runner
- `playbooks/lxc_vault.yml`: instalación y configuración del servicio Vault
- `playbooks/lxc_postgres.yml`: instalación y habilitación de PostgreSQL
- `playbooks/vm_k3s.yml`: instalación y arranque de K3s
- `scripts/render_inventory_from_tf.sh`: genera inventario desde salidas de Terraform

## Flujo de ejecución

1. Desplegar la infraestructura con Terraform (desde `code/terraform`):

```bash
terraform init
terraform apply
```

2. Generar el inventario a partir de salidas de Terraform:

```bash
cd code/ansible
chmod +x scripts/render_inventory_from_tf.sh
./scripts/render_inventory_from_tf.sh
```

3. Ejecutar todos los playbooks de aprovisionamiento:

```bash
ansible-playbook playbooks/site.yml
```

4. Comprobación opcional (conectividad y datos remotos):

```bash
ansible all -m ping
ansible all -m command -a "cat /etc/tfm-node-role"
```

## Notas

- El inventario asume acceso SSH mediante clave.
- El bootstrap de Vault por Terraform es opcional (`enable_vault_bootstrap`).
- Los playbooks están diseñados para ser idempotentes y seguros al re-ejecutarse.
