output "lxc_gitea_ip" {
  value = proxmox_virtual_environment_container.lxc_gitea.initialization[0].ip_config[0].ipv4[0].address
}

output "lxc_vault_ip" {
  value = proxmox_virtual_environment_container.lxc_vault.initialization[0].ip_config[0].ipv4[0].address
}

output "lxc_postgres_ip" {
  value = proxmox_virtual_environment_container.lxc_postgres.initialization[0].ip_config[0].ipv4[0].address
}

output "vm_k3s_ip" {
  value = proxmox_virtual_environment_vm.vm_k3s.initialization[0].ip_config[0].ipv4[0].address
}