packer {
  required_plugins {
    proxmox = {
      version = " >= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "PROXMOX_URL" {
    type = string #"https://x.x.x.x:{port}/api2/json"
}

variable "PROXMOX_TOKEN_ID" {
    type    = string
}

variable "PROXMOX_TOKEN_SECRET" {
    type      = string
    sensitive = true
}

variable "PRIVATE_SSH_KEY" {
    type    = string # ~/.ssh/id_rsa
}

variable "PUBLIC_SSH_KEY" {
    type    = string # ~/.ssh/id_rsa.pub
}

variable "vm_user" {
    type    = string
}

variable "proxmox_storage" {
    type    = string
}

variable "iso_url" {
    type    = string
    default = "https://releases.ubuntu.com/24.04/ubuntu-24.04.2-live-server-amd64.iso"
}

variable "iso_checksum" {
    type    = string
    default = "d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
}

variable "iso_storage_pool" {
    type    = string
}

variable "vm_id" {
  type = string
}

variable "proxmox_node" {
  type = string
}

locals {
  # read and trim the SSH public key file into a single string
  ssh_pub_key = trimspace(file(var.PUBLIC_SSH_KEY))
}

# add ssh key for the cloud-init
source "file" "user_data" {
  content = templatefile("./http/user-data.tpl", {
    ssh_pub_key = local.ssh_pub_key
    vm_user     = var.vm_user
  })
  target  = "./http/user-data"
}

# Resource Definiation for the VM Template
source "proxmox-iso" "sf-ubuntu-server-noble" {

    # Proxmox Connection Settings
    proxmox_url              = "${var.PROXMOX_URL}"
    username                 = "${var.PROXMOX_TOKEN_ID}"
    token                    = "${var.PROXMOX_TOKEN_SECRET}"
    insecure_skip_tls_verify = true

    # VM General Settings
    node                 = var.proxmox_node
    vm_id                = var.vm_id
    vm_name              = "sf-ubuntu-server-noble-template"
    template_description = "SF Ubuntu Server Noble Image"

    boot_iso {
        # (Option 1) Local ISO File
        # iso_file = "${var.proxmox_iso_file}"
        # - or -
        # (Option 2) Download ISO
        iso_url          = "${var.iso_url}"
        iso_checksum     = "${var.iso_checksum}"
        iso_storage_pool = "${var.iso_storage_pool}"
        unmount          = true
    }

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size    = "20G"
        format       = "raw"
        storage_pool = var.proxmox_storage
        type         = "virtio"
    }

    cores  = "4"
    memory = "4048"

    # VM Network Settings
    network_adapters {
        model    = "virtio"
        bridge   = "vmbr0"
        firewall = "false"
    }

    # VM Cloud-Init Settings
    cloud_init              = true
    cloud_init_storage_pool = var.proxmox_storage

    # PACKER Boot Commands
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
    ]

    boot                    = "c"
    boot_wait               = "10s"
    communicator            = "ssh"
    os                      = "l26"

    # PACKER Autoinstall Settings
    http_directory          = "http"
    ssh_username            = var.vm_user
    ssh_private_key_file    = "${var.PRIVATE_SSH_KEY}"
    ssh_timeout             = "30m"
    ssh_pty                 = true
}

# Build Definition to create the VM Template
build {

    name = "sf-ubuntu-server-noble"
    sources = [
        "source.file.user_data",
        "source.proxmox-iso.sf-ubuntu-server-noble"
    ]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source      = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }
}
