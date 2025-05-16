#cloud-config
autoinstall:
  version: 1
  locale: en_US
  keyboard:
    layout: us
  ssh:
    install-server: true
    allow-pw: true
    disable_root: true
    ssh_quiet_keygen: true
    allow_public_ssh_keys: true
  packages:
    - qemu-guest-agent
    - sudo
  storage:
    layout:
      name: direct
    swap:
      size: 0
  timezone: Europe/Berlin
  user-data:
    package_upgrade: false
    users:
      - name: ${vm_user}
        groups: [adm, sudo]
        lock-passwd: false
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${ssh_pub_key}