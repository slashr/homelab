variable "cloudflare_api_token" {
  description = "Cloudflare API token with necessary DNS permissions"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.cloudflare_api_token) > 0
    error_message = "Cloudflare API token cannot be empty."
  }
}

variable "letsencrypt_prod_email" {
  description = "Email address registered with Let's Encrypt for the production ClusterIssuer"
  type        = string
  default = "admin@shrub.dev"
  validation {
    condition     = can(regex("^[^@]+@[^@]+[.][^@]+$", var.letsencrypt_prod_email))
    error_message = "letsencrypt_prod_email must be a valid email address."
  }
}

# Raspberry Pi variables
variable "kube_client_cert" {
  description = "Rpi Kube cluster certificate base64 encoded"
  type        = string
  sensitive   = true
  validation {
    condition     = can(base64decode(var.kube_client_cert))
    error_message = "kube_client_cert must be valid base64-encoded data."
  }
}

variable "kube_client_key" {
  description = "Rpi Kube client key base64 encoded"
  type        = string
  sensitive   = true
  validation {
    condition     = can(base64decode(var.kube_client_key))
    error_message = "kube_client_key must be valid base64-encoded data."
  }
}
