terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.46.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = true # Solo para entornos de laboratorio locales sin CA interna
}

# ==========================================
# LXC 1: Gitea + Act Runner
# ==========================================
resource "proxmox_virtual_environment_container" "lxc_gitea" {
  node_name = var.proxmox_node
  vm_id     = 501

  initialization {
    hostname = "gitea-runner"
    ip_config {
      ipv4 {
        address = "10.0.0.11/24"
        gateway = "10.0.0.1"
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
  vm_id     = 502

  initialization {
    hostname = "vault-server"
    ip_config {
      ipv4 {
        address = "10.0.0.20/24"
        gateway = "10.0.0.1"
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
  vm_id     = 503

  initialization {
    hostname = "postgres-db"
    ip_config {
      ipv4 {
        address = "10.0.0.30/24"
        gateway = "10.0.0.1"
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
  vm_id     = 504
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
    ip_config {
      ipv4 {
        address = "10.0.0.40/24"
        gateway = "10.0.0.1"
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