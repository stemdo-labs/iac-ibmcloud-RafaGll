terraform {
  required_version = "1.6.6"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.55.0"
    }
  }
  # backend "s3" {
  #   bucket         = "tfstatecont-ibm"
  #   key            = "terraform.tfstate"
  #   region         = "eu-de"
  #   access_key     = "your-ibm-access-key"
  #   secret_key     = "your-ibm-secret-key"
  # }
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
}

# Public IP para VM de backups
resource "ibm_is_floating_ip" "vm_backup_ip" {
  name     = "${var.name}-public-ip-backup"
  zone     = var.zone
  resource_group = var.resource_group_id
  tags     = ["DevOps Final"]
}

# Interfaz de Red para la VM de Backups
resource "ibm_is_network_interface" "nic_backup" {
  name            = "${var.name}-nic-backup"
  subnet          = var.subnet_id
  primary_ip      = "dynamic"
  floating_ip     = ibm_is_floating_ip.vm_backup_ip.id
  resource_group  = var.resource_group_id
  tags            = ["DevOps Final"]
}

# Registro de Contenedores
resource "ibm_container_registry" "acr" {
  name            = "acrfinalprojectrafa"
  resource_group  = var.resource_group_id
  plan            = "free"
  tags            = ["DevOps Final"]
}

output "acr_login_server" {
  description = "Login server of the IBM Container Registry"
  value       = ibm_container_registry.acr.endpoint
}

output "resource_group_id" {
  description = "ID del Resource Group"
  value       = var.resource_group_id
}

output "vm_backup_private_ip" {
  description = "Dirección IP privada de la máquina virtual de backups"
  value       = ibm_is_network_interface.nic_backup.primary_ip
}

# Máquina Virtual para Backups
resource "ibm_is_instance" "vm_backup" {
  name              = "${var.name}-vm-backup"
  profile           = "bx2-2x8"
  zone              = var.zone
  image             = "ubuntu-22-04-amd64"
  primary_network_interface {
    subnet          = var.subnet_id
    floating_ip     = ibm_is_floating_ip.vm_backup_ip.id
  }
  keys              = [var.ssh_key]
  resource_group    = var.resource_group_id
  user_data         = base64encode(<<-EOF
#!/bin/bash
sudo apt-get update && sudo apt-get install -y curl tar jq
mkdir -p /actions-runner && cd /actions-runner
curl -o actions-runner-linux-x64-2.320.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.320.0/actions-runner-linux-x64-2.320.0.tar.gz
tar xzf actions-runner-linux-x64-2.320.0.tar.gz
sudo chmod +x config.sh svc.sh
sudo -u ${var.vm_username} ./config.sh \
  --url https://github.com/stemdo-labs/final-project-exercise-RafaGll \
  --token "${var.github_runner_token}" \
  --unattended \
  --replace \
  --labels backup_runner > config.txt
sudo ./svc.sh install > inicio.txt
sudo ./svc.sh start >> inicio.txt
EOF
  )
  tags = ["DevOps Final"]
}

# Variables
variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key"
  type        = string
  sensitive   = true
}

variable "zone" {
  description = "Zona de IBM Cloud para los recursos"
  type        = string
}

variable "resource_group_id" {
  description = "ID del Resource Group"
  type        = string
}

variable "subnet_id" {
  description = "ID de la Subred"
  type        = string
}

variable "name" {
  description = "Nombre de los recursos"
  type        = string
}

variable "vm_username" {
  description = "Nombre de usuario administrador para las VMs"
  type        = string
}

variable "github_runner_token" {
  description = "Token para registrar el runner de GitHub Actions"
  type        = string
  sensitive   = true
}

variable "ssh_key" {
  description = "Clave SSH para las VMs"
  type        = string
}
