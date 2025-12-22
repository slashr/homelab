variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for DNS records"
  type        = string
}

variable "tunnel_name" {
  description = "Name for the Cloudflare Tunnel"
  type        = string
  default     = "homelab-ha"
}

variable "tunnel_hostnames" {
  description = "List of hostnames to route through the tunnel"
  type        = list(string)
  default = [
    "argo.shrub.dev",
  ]
}
