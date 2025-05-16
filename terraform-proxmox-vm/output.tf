# output "IPv4_address" {
#   value = proxmox_vm_qemu.your-vm.default_ipv4_address
# }

# output "ansible_inventory" {
#   value = <<EOF
# [ubuntu]
# ${var.external_ip} ansible_user=ubuntu ansible_private_key_file=./id_rsa
# EOF
# }