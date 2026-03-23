# Ansible provisioning for TFM lab

This directory configures each Terraform-created node in the lab:

- `gitea-runner` (LXC)
- `vault-server` (LXC)
- `postgres-db` (LXC)
- `k3s-cluster` (VM)

## Structure

- `ansible.cfg`: common runtime settings
- `inventories/lab/hosts.yml`: static inventory (default IPs)
- `playbooks/site.yml`: orchestrates all node playbooks
- `playbooks/lxc_gitea.yml`: baseline for Gitea runner node
- `playbooks/lxc_vault.yml`: installs and configures Vault service
- `playbooks/lxc_postgres.yml`: installs and enables PostgreSQL
- `playbooks/vm_k3s.yml`: installs and starts K3s
- `scripts/render_inventory_from_tf.sh`: builds inventory from Terraform outputs

## Execution flow

1. Deploy infrastructure with Terraform (from `code/terraform`):

```bash
terraform init
terraform apply
```

2. Generate inventory from Terraform outputs:

```bash
cd code/ansible
chmod +x scripts/render_inventory_from_tf.sh
./scripts/render_inventory_from_tf.sh
```

3. Run all provisioning playbooks:

```bash
ansible-playbook playbooks/site.yml
```

4. Optional check (connectivity and remote facts):

```bash
ansible all -m ping
ansible all -m command -a "cat /etc/tfm-node-role"
```

## Notes

- The inventory expects SSH key-based access.
- Vault bootstrap via Terraform remains optional (`enable_vault_bootstrap`).
- Playbooks are designed to be idempotent and safe to rerun.
