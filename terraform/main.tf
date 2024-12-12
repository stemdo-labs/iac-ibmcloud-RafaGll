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
  name = "vpc-rafa"
  resource_group   = ibm_resource_group.rg_rafa.id
}

output "resource_group_id" {
  description = "ID del grupo de recursos creado."
  value       = ibm_resource_group.rg_rafa.id
}