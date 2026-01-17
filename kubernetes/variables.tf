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
  default     = "admin@shrub.dev"
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

variable "kube_cluster_ca_cert" {
  description = "Rpi Kube cluster CA certificate base64 encoded"
  type        = string
  sensitive   = true
  validation {
    condition     = can(base64decode(var.kube_cluster_ca_cert))
    error_message = "kube_cluster_ca_cert must be valid base64-encoded data."
  }
}

# Tailscale operator variables
variable "tailscale_oauth_client_id" {
  description = "Tailscale OAuth client ID for the Kubernetes operator"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.tailscale_oauth_client_id) > 0
    error_message = "Tailscale OAuth client ID cannot be empty."
  }
}

variable "tailscale_oauth_client_secret" {
  description = "Tailscale OAuth client secret for the Kubernetes operator"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.tailscale_oauth_client_secret) > 0
    error_message = "Tailscale OAuth client secret cannot be empty."
  }
}

# Velero backup variables (OCI Object Storage S3-compatible credentials)
variable "velero_s3_access_key" {
  description = "OCI S3 access key for Velero backups"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.velero_s3_access_key) > 0
    error_message = "Velero S3 access key cannot be empty."
  }
}

variable "velero_s3_secret_key" {
  description = "OCI S3 secret key for Velero backups"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.velero_s3_secret_key) > 0
    error_message = "Velero S3 secret key cannot be empty."
  }
}

# OpenAI API key (for homelab-map AI features)
variable "openai_api_key" {
  description = "OpenAI API key for homelab-map AI features"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.openai_api_key) > 0
    error_message = "OpenAI API key cannot be empty."
  }
}
