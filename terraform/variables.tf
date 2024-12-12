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