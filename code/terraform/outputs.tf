output "lxc_gitea_ip" {
  value = proxmox_virtual_environment_container.lxc_gitea.initialization[0].ip_config[0].ipv4[0].address
}

output "lxc_gitea_info" {
  value = {
    node_name = proxmox_virtual_environment_container.lxc_gitea.node_name
    vm_id     = proxmox_virtual_environment_container.lxc_gitea.vm_id
    hostname  = proxmox_virtual_environment_container.lxc_gitea.initialization[0].hostname
  }
}

output "lxc_vault_ip" {
  value = proxmox_virtual_environment_container.lxc_vault.initialization[0].ip_config[0].ipv4[0].address
}

output "lxc_vault_info" {
  value = {
    node_name = proxmox_virtual_environment_container.lxc_vault.node_name
    vm_id     = proxmox_virtual_environment_container.lxc_vault.vm_id
    hostname  = proxmox_virtual_environment_container.lxc_vault.initialization[0].hostname
  }
}

output "lxc_postgres_ip" {
  value = proxmox_virtual_environment_container.lxc_postgres.initialization[0].ip_config[0].ipv4[0].address
}

output "lxc_postgres_info" {
  value = {
    node_name = proxmox_virtual_environment_container.lxc_postgres.node_name
    vm_id     = proxmox_virtual_environment_container.lxc_postgres.vm_id
    hostname  = proxmox_virtual_environment_container.lxc_postgres.initialization[0].hostname
  }
}

output "vm_k3s_ip" {
  value = proxmox_virtual_environment_vm.vm_k3s.initialization[0].ip_config[0].ipv4[0].address
}

output "vm_k3s_info" {
  value = {
    node_name = proxmox_virtual_environment_vm.vm_k3s.node_name
    vm_id     = proxmox_virtual_environment_vm.vm_k3s.vm_id
    name      = proxmox_virtual_environment_vm.vm_k3s.name
  }
}

output "vault_bootstrap_enabled" {
  value = var.enable_vault_bootstrap
}

output "vault_db_role_name" {
  value = var.enable_vault_bootstrap ? vault_database_secret_backend_role.readonly[0].name : null
}