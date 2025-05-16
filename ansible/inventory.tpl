all:
  children:
    ubuntu:
      hosts:
        ${ip}:
          ansible_user: ${vm_user}
          ansible_private_key_file: ${ssh_key}