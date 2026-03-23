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

variable "ssh_public_key" {
  type        = string
  description = "Clave publica SSH para inyectar en las maquinas"

  validation {
    condition     = length(trim(var.ssh_public_key)) > 0
    error_message = "ssh_public_key no puede estar vacia."
  }
}

variable "lxc_template_id" {
  type        = string
  description = "ID del template LXC de Debian/Ubuntu"
  default     = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
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
    gitea    = "10.0.0.11/24"
    vault    = "10.0.0.20/24"
    postgres = "10.0.0.30/24"
    k3s      = "10.0.0.40/24"
    gateway  = "10.0.0.1"
  }
}