variable "proxmox_endpoint" {
  type        = string
  description = "URL de la API de Proxmox"
  default     = "https://10.0.0.10:8006/"
}

variable "proxmox_node" {
  type        = string
  description = "Nombre del nodo de Proxmox"
  default     = "pve"
}

variable "ssh_public_key" {
  type        = string
  description = "Clave publica SSH para inyectar en las maquinas"
}

variable "lxc_template_id" {
  type        = string
  description = "ID del template LXC de Debian/Ubuntu"
  default     = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
}