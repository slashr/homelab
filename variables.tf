variable "cloudflare_api_token" {
  type = string
}

variable "kube_client_cert" {
  type = string
}

variable "kube_client_key" {
  type = string
}

# Oracle Cloud Infrastructure Variables
variable "oci_region" {
  description = "The region to connect to. Default: eu-frankfurt-1"
  type        = string
  default     = "eu-frankfurt-1"
}

variable "config_file_profile" {
  description = "The config profile to use for OCI authentication"
  type        = string
  default     = "DEFAULT"
}

variable "ampere_source_image_id" {
  description = "OCID of the ampere image"
  type        = string
}

variable "amd_source_image_id" {
  description = "OCID of the amd image"
  type        = string
}

variable "ampere_boot_volume_size" {
  description = "Size of the boot volume in GBs"
  type        = number
}

variable "amd_boot_volume_size" {
  description = "Size of the boot volume in GBs"
  type        = number
}

variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
  sensitive   = true
}

variable "private_key" {
  type = string
}
