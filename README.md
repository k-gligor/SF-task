For successfully deployment following assumptions are made:
 - For this task we will use Proxmox for hosting the VM and thus we assume that it is installed and accessible from the deployment machine
 - Token for this user is created
 - Storage created for storing images, templates and vms
 - User with appropriate privileges is created on the proxmox server
 - On the proxmox, these 3 bridges are already setup, and they are (i have used harcoded values to lower the number of variables):
    - vmbr1 for VLAN100, hosting external ip addreses
    - vmbr2 for VLAN150, hosting the vlan 150
    - vmbr0 that serves IP addresses that can have 2 way communication between the local (provisioning machine) and the proxmox VM. The packer build process needs http access from the proxmox vm to the local machine during deployment
 - Have values for ip settings for the internal (VLAN150) and external network interfaces, and also for the vmbr0
 - Terraform, ansible and packer are installed and set on the deployment machine
 - As I don't have the values for the networks, i have put them to be variables so they can be provided during deployment
 - The network in question 10.200.16.100/29 has in total 6 available host addreses, of which 10.200.16.100 is taken, and i don't know which ones are available, I would choose the first available whoich is 10.200.16.97
 - Already have ssh key pair
 - Same values should be provided for:
   - PROXMOX_URL
   - PROXMOX_TOKEN_ID
   - PROXMOX_TOKEN_SECRET
   - vm_user
   - PUBLIC_SSH_KEY
   - proxmox_node


Deployment process:

To deploy a VM on the proxmox server we will use clones (template) as they support cloud-init customizations

1. Clone the GitHub repo and cd into it

2. Creating Proxmox vm template for ubuntu server

This is the process that will create a ubuntu 22.04.2 proxmox clone (template) that we can use for deploying the ubuntu vm


From the "packer-proxmox-template" dir:

Initialize packer along with the required plugin, and deploy.
Before executing the command, fill the values.
Examples and descriptions are in the hcl file.

packer init .
packer.exe build `
-var "PROXMOX_URL=" `
-var "PROXMOX_TOKEN_ID=" `
-var "PROXMOX_TOKEN_SECRET=" `
-var "PUBLIC_SSH_KEY=" `
-var "PRIVATE_SSH_KEY=" `
-var "vm_user=" `
-var "proxmox_storage=" `
-var "iso_storage_pool=" `
-var "proxmox_node=" `
-var "vm_id=" .

This will download the 24.04.2 ubuntu server localy, send it to the proxmox server and deploy the clone (template). It is hardcoded also for lowering the number of variables.
Beacuse we need to automate the deployment, we need to use cloud-init and for this packer and the proxmox plugin create a simple webserver on the deployment machine that host the autoinstall config file (user-data).
Because of this, we need the vmbr0 that has 2 way communication.
The user-data is automatically created using packer template resource

2. Deploying Proxmox VM for Ubuntu server

From the "terraform-proxmox-vm" dir:

Initialize terraform and required providers and deploy.
Before executing the command, fill the values.
Examples and descriptions are in the variables file.

terraform init
terraform apply `
-var "PROXMOX_URL=" `
-var "PROXMOX_TOKEN_ID=" `
-var "PROXMOX_TOKEN_SECRET=" `
-var "PUBLIC_SSH_KEY=" `
-var "proxmox_storage=" `
-var "external_ip=" `
-var "external_gw=" `
-var "internal_ip=" `
-var "internal_gw=" `
-var "vm_id=" `
-var "vm_name=" `
-var "vm_description=" `
-var "proxmox_node=" `
-var "vm_user="

This will automatically create the inventory file for the ansible deployment.
It is using the telmate/proxmox provide for working with the proxmox server.
Will use the clone(template, that packer built, for deploying the ubuntu VM.

4. Hardening the Ubuntu VM using Ansible

From the root of the repo:

ansible-playbook -i ansible/inventory ansible/site.yml

This will use the inventory file cerated from the terraform deployment stage.
It will:
 - update and upgrade ubuntu packeges
 - install nginx
 - set ssh to listen only on the external IP
 - enable the default nginx site
 - install fail2ban
 - allow HTTP only on the external IP
 - Allow internal device access to port 9000 only on the internal interface
 - disable all other traffic
 - disable ssh password auth
 - disable ssh root login
 - disable IPv4 packet forwarding on the host. Prevents the VM from acting as a router.
 - enable reverse‐path filtering on all interfaces. The kernel will drop any incoming packet whose source address doesn’t match the routing table’s expected interface.
 - set the previous hardening to be applied to any interface created in the future.