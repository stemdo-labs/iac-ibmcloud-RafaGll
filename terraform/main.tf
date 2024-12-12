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

variable "ibmcloud_api_key" {
  description = "API key para autenticar con IBM Cloud."
  type        = string
  default = "ngznEKwz87tO6VWwNDtYGApkpsWE3FYEwuw_ES1LT4j2"
  sensitive   = true
}

variable "region" {
  description = "Región donde se desplegarán los recursos."
  type        = string
  default     = "eu-gb"
}

resource "ibm_resource_group" "rg_rafa" {
  name = "Stemdo_Sandbox"
}
import {
  id = "4364ced224cf420fa07d8bf70a8d70df"
  to = ibm_resource_group.rg_rafa
}

output "resource_group_id" {
  description = "ID del grupo de recursos creado."
  value       = ibm_resource_group.rg_rafa.id
}