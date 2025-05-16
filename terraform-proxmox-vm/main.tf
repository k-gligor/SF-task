terraform {
  required_version = ">= 0.13.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc8"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.PROXMOX_URL
  pm_api_token_id     = var.PROXMOX_TOKEN_ID
  pm_api_token_secret = var.PROXMOX_TOKEN_SECRET

  pm_tls_insecure = true
}

locals {
  public_key = trimspace(file(var.PUBLIC_SSH_KEY))
}

resource "proxmox_vm_qemu" "your-vm" {

  name  = var.vm_name
  desc  = var.vm_description
  agent = 1


  target_node = var.proxmox_node

  vmid = var.vm_id

  clone      = "sf-ubuntu-server-noble-template"
  full_clone = true

  onboot = true

  startup          = ""
  automatic_reboot = false

  qemu_os  = "other"
  bios     = "seabios"
  cores    = 4
  sockets  = 1
  cpu_type = "host"
  memory   = 4048

  network {
    id     = 0
    bridge = "vmbr1"
    model  = "virtio"
  }

  network {
    id     = 1
    bridge = "vmbr2"
    model  = "virtio"
  }

  scsihw = "virtio-scsi-single"

  disks {
    ide {
      ide0 {
        cloudinit {
          storage = var.proxmox_storage
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          storage   = var.proxmox_storage
          size      = "20G"
          iothread  = true
          replicate = false
        }
      }
    }
  }


  ipconfig0 = "ip=${var.external_ip},gw=${var.external_gw}"
  ipconfig1 = "ip=${var.internal_ip},gw=${var.internal_gw}"
  ciuser    = var.vm_user
  sshkeys   = local.public_key
}

# Create inventory file from template using output from vm resource
data "template_file" "ansible_inventory" {
  template = file("../ansible/inventory.tpl")
  vars = {
    ip      = proxmox_vm_qemu.your-vm.default_ipv4_address
    vm_user = var.vm_user
    ssh_key = var.PUBLIC_SSH_KEY
  }
}

resource "local_file" "ansible_inventory_yaml" {
  content  = data.template_file.ansible_inventory.rendered
  filename = "../ansible/inventory"
  file_permission = "0644"
}