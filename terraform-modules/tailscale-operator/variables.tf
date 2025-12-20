variable "namespace" {
  description = "Namespace to install tailscale-operator in"
  type        = string
  default     = "tailscale"
}

variable "chart_version" {
  description = "The Helm chart version to install"
  type        = string
  default     = "1.92.4"
}

variable "timeout" {
  description = "Helm chart timeout"
  type        = number
  default     = 600
}

variable "oauth_client_id" {
  description = "Tailscale OAuth client ID"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.oauth_client_id) > 0
    error_message = "OAuth client ID cannot be empty."
  }
}

variable "oauth_client_secret" {
  description = "Tailscale OAuth client secret"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.oauth_client_secret) > 0
    error_message = "OAuth client secret cannot be empty."
  }
}
