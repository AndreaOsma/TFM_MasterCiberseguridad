variable "proxmox_endpoint" {
  type        = string
  description = "URL de la API de Proxmox"
  default     = "https://10.0.0.10:8006/"
}

variable "proxmox_insecure" {
  type        = bool
  description = "Permite omitir la validacion TLS del endpoint (true en laboratorio local)."
  default     = true
}

variable "proxmox_node" {
  type        = string
  description = "Nombre del nodo de Proxmox"
  default     = "pve"
}

variable "proxmox_username" {
  type        = string
  description = "Usuario para autenticacion contra la API de Proxmox (ej: user@pve)."
  default     = ""
}

variable "proxmox_password" {
  type        = string
  description = "Contrasena para autenticacion de API en Proxmox. Definir via tfvars/entorno."
  default     = ""
  sensitive   = true
}

variable "ssh_public_key" {
  type        = string
  description = "Clave publica SSH para inyectar en las maquinas"

  validation {
    condition     = length(trimspace(var.ssh_public_key)) > 0
    error_message = "ssh_public_key no puede estar vacia."
  }
}

variable "lxc_template_id" {
  type        = string
  description = "ID del template LXC de Debian/Ubuntu"
  default     = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
}

variable "vm_ids" {
  description = "IDs de recursos en Proxmox para el laboratorio."
  type = object({
    gitea    = number
    vault    = number
    postgres = number
    k3s      = number
  })
  default = {
    gitea    = 501
    vault    = 502
    postgres = 503
    k3s      = 504
  }
}

variable "lab_ipv4" {
  description = "Direccionamiento IPv4 del laboratorio (con CIDR)."
  type = object({
    gitea    = string
    vault    = string
    postgres = string
    k3s      = string
    gateway  = string
  })
  default = {
    gitea    = "192.168.1.211/24"
    vault    = "192.168.1.220/24"
    postgres = "192.168.1.230/24"
    k3s      = "192.168.1.240/24"
    gateway  = "192.168.1.1"
  }
}

variable "enable_vault_bootstrap" {
  type        = bool
  description = "Habilita la configuracion de Vault (policy + database secrets engine) desde Terraform."
  default     = false
}

variable "vault_address" {
  type        = string
  description = "URL de Vault (ej: http://10.0.0.20:8200)."
  default     = "http://192.168.1.220:8200"
}

variable "vault_token" {
  type        = string
  description = "Token de Vault con permisos para configurar auth/policies/secrets engines."
  default     = ""
  sensitive   = true
}

variable "vault_db_admin_username" {
  type        = string
  description = "Usuario administrador de PostgreSQL usado por Vault para crear roles dinamicos."
  default     = "postgres"
}

variable "vault_db_admin_password" {
  type        = string
  description = "Contrasena del usuario administrador de PostgreSQL para Vault database secrets engine."
  default     = ""
  sensitive   = true
}