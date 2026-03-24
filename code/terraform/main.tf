terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.46.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.5"
    }
  }
}

provider "proxmox" {
  # Credenciales fuera de código: se pasan por tfvars/variables de entorno.
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure # Solo para entornos de laboratorio locales sin CA interna
}

provider "vault" {
  # Se usa para bootstrap opcional del motor de secretos dinámicos.
  address = var.vault_address
  token   = var.vault_token
}

# ==========================================
# LXC 1: Gitea + Act Runner
# ==========================================
resource "proxmox_virtual_environment_container" "lxc_gitea" {
  node_name = var.proxmox_node
  vm_id     = var.vm_ids.gitea

  initialization {
    # Inyección temprana de clave SSH para evitar acceso por contraseña.
    hostname = "gitea-runner"
    ip_config {
      ipv4 {
        address = var.lab_ipv4.gitea
        gateway = var.lab_ipv4.gateway
      }
    }
    user_account {
      keys = [var.ssh_public_key]
    }
  }

  disk {
    datastore_id = "nvme-data"
    size         = 20
  }

  cpu { cores = 2 }
  memory { dedicated = 2048 }

  operating_system {
    template_file_id = var.lxc_template_id
    type             = "debian"
  }
}

# ==========================================
# LXC 2: HashiCorp Vault
# ==========================================
resource "proxmox_virtual_environment_container" "lxc_vault" {
  node_name = var.proxmox_node
  vm_id     = var.vm_ids.vault

  initialization {
    hostname = "vault-server"
    ip_config {
      ipv4 {
        address = var.lab_ipv4.vault
        gateway = var.lab_ipv4.gateway
      }
    }
    user_account {
      keys = [var.ssh_public_key]
    }
  }

  disk {
    datastore_id = "nvme-data"
    size         = 10
  }

  cpu { cores = 2 }
  memory { dedicated = 2048 }

  operating_system {
    template_file_id = var.lxc_template_id
    type             = "debian"
  }
}

# ==========================================
# LXC 3: PostgreSQL
# ==========================================
resource "proxmox_virtual_environment_container" "lxc_postgres" {
  node_name = var.proxmox_node
  vm_id     = var.vm_ids.postgres

  initialization {
    hostname = "postgres-db"
    ip_config {
      ipv4 {
        address = var.lab_ipv4.postgres
        gateway = var.lab_ipv4.gateway
      }
    }
    user_account {
      keys = [var.ssh_public_key]
    }
  }

  disk {
    datastore_id = "nvme-data"
    size         = 20
  }

  cpu { cores = 2 }
  memory { dedicated = 4096 }

  operating_system {
    template_file_id = var.lxc_template_id
    type             = "debian"
  }
}

# ==========================================
# VM 1: K3s (Kubernetes)
# ==========================================
resource "proxmox_virtual_environment_vm" "vm_k3s" {
  node_name = var.proxmox_node
  vm_id     = var.vm_ids.k3s
  name      = "k3s-cluster"

  agent {
    enabled = true
  }

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = "nvme-data"
    file_format  = "raw"
    interface    = "scsi0"
    size         = 40
  }

  initialization {
    # VM con usuario no-root para alinear con buenas prácticas de acceso.
    ip_config {
      ipv4 {
        address = var.lab_ipv4.k3s
        gateway = var.lab_ipv4.gateway
      }
    }
    user_account {
      username = "debian"
      keys     = [var.ssh_public_key]
    }
  }

  # Requiere una imagen Cloud-Init precargada en Proxmox
  # file_id = "local:iso/debian-12-genericcloud-amd64.img"
}