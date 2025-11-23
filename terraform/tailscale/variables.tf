variable "tailscale_api_key" {
  type        = string
  description = "Tailscale API key with ACL edit permission"
  sensitive   = true
}

variable "tailscale_tailnet" {
  type        = string
  description = "Tailnet identifier (ID)"
}

locals {
  tailscale_tailnet_id = var.tailscale_tailnet
}
