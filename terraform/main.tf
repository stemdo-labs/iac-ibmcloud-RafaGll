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
  sensitive   = true
}

variable "region" {
  description = "Región donde se desplegarán los recursos."
  type        = string
  default     = "eu-gb"
}

resource "ibm_resource_group" "example" {
  name = "example-resource-group"
}

output "resource_group_id" {
  description = "ID del grupo de recursos creado."
  value       = ibm_resource_group.example.id
}