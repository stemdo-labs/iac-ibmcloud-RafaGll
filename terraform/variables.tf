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