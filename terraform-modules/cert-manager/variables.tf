variable "namespace" {
  description = "Namespace to install cert-manager in."
  type        = string
  default     = "cert-manager"
}

variable "chart_version" {
  description = "The chart version to install. (Should match the cert-manager crd release version.)"
  type        = string
  default     = "1.16.3"
}

variable "timeout" {
  description = "Helm chart timeout"
  type        = string
  default     = "1200"
}

variable "cert_issuer_url_map" {
  type = map(string)
  default = {
    dev     = "https://acme-staging-v02.api.letsencrypt.org/directory"
    staging = "https://acme-v02.api.letsencrypt.org/directory"
    prod    = "https://acme-v02.api.letsencrypt.org/directory"
  }
}

variable "cloudflare_api_token" {
  type = string
}
