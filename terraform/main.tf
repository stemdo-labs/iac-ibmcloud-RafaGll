terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.55.0" # Cambia según la última versión soportada
    }
  }

  required_version = ">=1.6.0"
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}
resource "ibm_resource_group" "rg_rafa" {
  name = "Stemdo_Sandbox"
}
import {
  id = "4364ced224cf420fa07d8bf70a8d70df"
  to = ibm_resource_group.rg_rafa
}


resource "ibm_is_vpc" "vpc_rafa" {
  # name             = var.vpc_name
  name           = "vpc-rafa"
  resource_group = var.resource_group_id
}

resource "ibm_is_subnet" "subnet_rafa" {
  name            = "subnet-rafa"
  vpc             = ibm_is_vpc.vpc_rafa.id
  zone            = "eu-gb-1"
  resource_group  = var.resource_group_id
  ipv4_cidr_block = "10.242.1.0/24"
}

resource "ibm_is_security_group" "security_group" {
  name           = "ssh-security-group"
  vpc            = ibm_is_vpc.vpc_rafa.id
  resource_group = var.resource_group_id
}
resource "ibm_is_security_group_rule" "internet" {
  group     = ibm_is_security_group.security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_security_group_rule" "ssh_rule" {
  group     = ibm_is_security_group.security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_floating_ip" "public_ip" {
  name           = "public-ip-rafa"
  target         = ibm_is_instance.vm_rafa.primary_network_interface[0].id
  resource_group = var.resource_group_id
  depends_on     = [ibm_is_instance.vm_rafa]

}
# Añadir un recurso para la clave SSH
resource "ibm_is_ssh_key" "ssh_key" {
  name           = "ssh-key-rafa"
  public_key     = <<-EOF
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCU94A3wzNYKAAYrOgQ6OGPcLVNYb73+FF5r/Vp/upSghDbdRzW95xm4BBTqaR+8Dm81UFycPjJlYnUaKYlrjGpTxKLoX6myC/RA0ddYH9WAD6ZRqdXepELdoikiZyvMOaMgOT5t6t9z9tWCuzkgvc5L8goYfHXzP44iGrkqR3Vf0Q3PmnHedFFFShbcT3p1vKR/9Z7VFF2my0Weg0C7tpE7VRBQ1dFlhzKCbAhWQ9SqZUowlh7/ASGzgX9K9czV6MtvE932YudPlSKrpD1GRejY+sndAfl1yOObyvKkUXmMjoqWIsRV3QBJtTNJNQk09MHMmwNEvTlW7T+ffe3Asqz user@stemdo
  EOF
  resource_group = var.resource_group_id
}

resource "ibm_is_public_gateway" "public_gateway_vm" {
  name           = "vpc-rafa"
  vpc            = ibm_is_vpc.vpc_rafa.id
  zone           = "eu-gb-1"
  resource_group = var.resource_group_id
}
# Crear una máquina virtual (instance)
resource "ibm_is_instance" "vm_rafa" {
  name    = "vm-rafa"
  vpc     = ibm_is_vpc.vpc_rafa.id
  profile = "bx2-2x8"
  zone    = ibm_is_subnet.subnet_rafa.zone
  image   = "r018-941eb02e-ceb9-44c8-895b-b31d241f43b5"
  
  primary_network_interface {
    subnet          = ibm_is_subnet.subnet_rafa.id
    security_groups = [ibm_is_security_group.security_group.id]
  }
  
  keys           = [ibm_is_ssh_key.ssh_key.id]
  resource_group = var.resource_group_id

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Variables
    USERNAME="stemdo"
    USER_HOME="/home/$USERNAME"
    GITHUB_REPO="https://github.com/stemdo-labs/iac-ibmcloud-RafaGll"
    RUNNER_VERSION="2.321.0"
    RUNNER_DIR="$USER_HOME/actions-runner"
    RUNNER_URL="https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"
    RUNNER_TAR="actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"

    # Crear un nuevo usuario
    useradd -m -s /bin/bash "$USERNAME"
    echo "$USERNAME:${var.user_password}" | chpasswd
    usermod -aG sudo "$USERNAME"

    # Configurar SSH
    mkdir -p "$USER_HOME/.ssh"
    chmod 700 "$USER_HOME/.ssh"
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCU94A3wzNYKAAYrOgQ6OGPcLVNYb73+FF5r/Vp/upSghDbdRzW95xm4BBTqaR+8Dm81UFycPjJlYnUaKYlrjGpTxKLoX6myC/RA0ddYH9WAD6ZRqdXepELdoikiZyvMOaMgOT5t6t9z9tWCuzkgvc5L8goYfHXzP44iGrkqR3Vf0Q3PmnHedFFFShbcT3p1vKR/9Z7VFF2my0Weg0C7tpE7VRBQ1dFlhzKCbAhWQ9SqZUowlh7/ASGzgX9K9czV6MtvE932YudPlSKrpD1GRejY+sndAfl1yOObyvKkUXmMjoqWIsRV3QBJtTNJNQk09MHMmwNEvTlW7T+ffe3Asqz user@stemdo" > "$USER_HOME/.ssh/authorized_keys"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.ssh"

    # Descargar y configurar el runner
    su - "$USERNAME" -c "mkdir -p $RUNNER_DIR && cd $RUNNER_DIR"
    su - "$USERNAME" -c "curl -o $RUNNER_TAR -L $RUNNER_URL"
    su - "$USERNAME" -c "tar xzf ./$RUNNER_TAR"

    # Obtener token de registro de GitHub
    TEMP_TOKEN=$(curl -s -X POST \
      -H "Authorization: token ${var.token}" \
      -H "Accept: application/vnd.github+json" \
      https://api.github.com/repos/stemdo-labs/iac-ibmcloud-RafaGll/actions/runners/registration-token | jq -r '.token')

    # Configurar el runner
    su - "$USERNAME" -c "./config.sh \
      --url $GITHUB_REPO \
      --token $TEMP_TOKEN \
      --unattended \
      --replace \
      --labels backup_runner > config.txt"

    # Instalar y iniciar el servicio del runner
    su - "$USERNAME" -c "sudo ./svc.sh install > inicio.txt"
    su - "$USERNAME" -c "sudo ./svc.sh start >> inicio.txt"
  EOF
}


resource "ibm_cr_namespace" "cr_namespace" {
  name              = "rafa-namespace"
  resource_group_id = var.resource_group_id
}

resource "ibm_cr_retention_policy" "cr_retention_policy" {
  namespace       = ibm_cr_namespace.cr_namespace.id
  images_per_repo = 10
}

resource "ibm_is_vpc" "vpc_cluster" {
  name           = "vpc-cluster-rafa"
  resource_group = var.resource_group_id
}

resource "ibm_is_security_group" "sg_cluster" {
  name           = "sg-cluster-rafa"
  vpc            = ibm_is_vpc.vpc_cluster.id
  resource_group = var.resource_group_id
}
resource "ibm_is_security_group_rule" "internet_cluster" {
  group     = ibm_is_security_group.sg_cluster.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}
resource "ibm_is_public_gateway" "public_gateway_cluster" {
  name           = "public-gateway-cluster-rafa"
  vpc            = ibm_is_vpc.vpc_cluster.id
  zone           = "eu-gb-1"
  resource_group = var.resource_group_id
}

resource "ibm_is_subnet" "subnet_cluster" {
  name            = "subnet-cluster-rafa"
  vpc             = ibm_is_vpc.vpc_cluster.id
  resource_group  = var.resource_group_id
  zone            = "eu-gb-1"
  ipv4_cidr_block = "10.242.0.0/24"
  public_gateway = ibm_is_public_gateway.public_gateway_cluster.id
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "cos-instance-rafa"
  location          = "global"
  service           = "cloud-object-storage"
  plan              = "standard"
  resource_group_id = var.resource_group_id
}

resource "ibm_container_vpc_cluster" "vpc_cluster" {
  name              = "vpc-cluster-rafa"
  resource_group_id = var.resource_group_id
  vpc_id            = ibm_is_vpc.vpc_cluster.id
  cos_instance_crn  = ibm_resource_instance.cos_instance.id
  worker_count      = "2"
  flavor            = "bx2.4x16"
  kube_version      = "4.16.23_openshift"
  zones {
    subnet_id = ibm_is_subnet.subnet_cluster.id
    name      = "eu-gb-1"
  }
}


output "public_ip" {
  description = "La IP pública de la máquina virtual"
  value       = ibm_is_floating_ip.public_ip.address
}

output "private_ip" {
  description = "La IP privada de la máquina virtual"
  value       = ibm_is_instance.vm_rafa.primary_network_interface[0].primary_ip
}
