variable "cloudflare_api_token" {
  type = string
}

# Raspberry Pi variables
variable "kube_client_cert" {
  description = "Rpi Kube cluster certificate base64 encoded" 
  type = string
}

variable "kube_client_key" {
  description = "Rpi Kube client key base64 encoded"
  type = string
}

# Oracle Cloud Infrastructure Variables
variable "oci_region" {
  description = "The region to connect to. Default: eu-frankfurt-1"
  type        = string
  default     = "eu-frankfurt-1"
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
  description = "Private key of the public-private key pair added to OCI account. Used for accessing the OCI API"
  type = string
}

variable "tenancy_ocid" {
  description = "ID of the OCI tenancy"
  type = string
}

variable "user_ocid" {
  description = "ID of the OCI user"
  type = string
}

variable "fingerprint" {
  description = "Fingerprint of the private key being used for OCI API authentication"
  type = string
}

variable "ssh_authorized_keys" {
  description = "Public SSH key added to authorized_keys file of new instances on OCI"
  type        = string
}
