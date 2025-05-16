variable "PROXMOX_URL" {
  type = string #"https://x.x.x.x:{port}/api2/json"
}

variable "PROXMOX_TOKEN_ID" {
  type      = string #"xxx@pam!root-token"
  sensitive = true
}

variable "PROXMOX_TOKEN_SECRET" {
  type      = string
  sensitive = true
}

variable "PUBLIC_SSH_KEY" {
  type      = string #"~/.ssh/key.pub"
  sensitive = true
}

variable "proxmox_storage" {
  type = string
}

variable "external_ip" {
  type = string # x.x.x.x/x
}

variable "external_gw" {
  type = string # x.x.x.x
}

variable "internal_ip" {
  type = string # x.x.x.x/x
}

variable "internal_gw" {
  type = string # x.x.x.x
}

variable "vm_id" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "vm_description" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "vm_user" {
  type = string
}