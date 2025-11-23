variable "tailscale_api_key" {
  type        = string
  description = "Tailscale API key with ACL edit permission"
  sensitive   = true
}

locals {
  tailscale_tailnet_id = "TwTN7rPx4921CNTRL"
}
