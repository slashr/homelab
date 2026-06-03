variable "sops_age_secret_key" {
  description = "AGE private key used by Argo CD to decrypt SOPS-encrypted manifests."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.sops_age_secret_key) > 0
    error_message = "sops_age_secret_key cannot be empty."
  }
}

variable "github_token" {
  description = "GitHub token used by Argo CD to read private slashr repositories."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.github_token) > 0
    error_message = "github_token cannot be empty."
  }
}
