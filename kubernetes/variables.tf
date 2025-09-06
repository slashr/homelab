variable "cloudflare_api_token" {
  description = "Cloudflare API token with necessary DNS permissions"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.cloudflare_api_token) > 0
    error_message = "Cloudflare API token cannot be empty."
  }
}

# Deprecated: use kube_cluster_ca_cert and kube_token instead
variable "kube_client_cert" {
  description = "(DEPRECATED) client certificate, will be removed in future"
  type        = string
  sensitive   = true
  default     = ""
}

variable "kube_client_key" {
  description = "(DEPRECATED) client key, will be removed in future"
  type        = string
  sensitive   = true
  default     = ""
}

variable "kube_cluster_ca_cert" {
  description = "Rpi Kube cluster CA certificate base64 encoded"
  type        = string
  sensitive   = true
  validation {
    condition     = can(base64decode(var.kube_cluster_ca_cert))
    error_message = "kube_cluster_ca_cert must be valid base64-encoded data."
  }
}

variable "kube_token" {
  description = "Bearer token for GitHub Actions ServiceAccount in the cluster"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.kube_token) > 0
    error_message = "kube_token cannot be empty."
  }
}
