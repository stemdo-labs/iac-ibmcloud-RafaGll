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

resource "ibm_is_security_group_rule" "ssh_rule" {
  group     = ibm_is_security_group.security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}
# Añadir un recurso para la clave SSH
resource "ibm_is_ssh_key" "ssh_key" {
  name           = "ssh-key-rafa"
  public_key     = <<-EOF
  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHiEOdwYl36RSushFuDIosheEYGOF91RdrIOyS1rfv4H rafaelgonzalezllamas2001@gmail.com
  EOF
  resource_group = var.resource_group_id
}

resource "ibm_is_public_gateway" "public_gateway_abermudez" {
  name           = "vpc-abermudez"
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
  image   = "ibm-ubuntu-22-04-1-minimal-amd64-2"
  primary_network_interface {
    subnet          = ibm_is_subnet.subnet_rafa.id
    security_groups = [ibm_is_security_group.security_group.id]
  }
  keys           = [ibm_is_ssh_key.ssh_key.id]
  resource_group = var.resource_group_id
}


