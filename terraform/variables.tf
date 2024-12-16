variable "resource_group_id"{
  description = "ID del grupo de recursos creado."
  type        = string
  default = "4364ced224cf420fa07d8bf70a8d70df"
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