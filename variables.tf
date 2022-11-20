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
  default     = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaj6g2lci5ed7nfhk46olwkhmwkzrobyo3jntnhkk7fnm2vqflorna"
}

variable "amd_source_image_id" {
  description = "OCID of the amd image"
  type        = string
  default     = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaab7wzikexyvn5vv5goyi3sgq7bx4ndwjiw6out2rvnheuaupwopba"
}

variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
  sensitive   = true
}

variable "oci_private_key" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "ssh_authorized_keys" {
  description = "Public SSH key added to authorized_keys file of new instances"
  type        = string
}
