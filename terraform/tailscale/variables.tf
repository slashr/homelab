variable "tailscale_api_key" {
  type        = string
  description = "Tailscale API key with ACL edit permission"
  sensitive   = true
}

variable "tailscale_device_hostnames" {
  type        = set(string)
  description = "Hostnames of devices that should have key expiry disabled"
  default = [
    "michael-pi",
    "jim-pi",
    "dwight-pi",
    "pam-amd1",
    "angela-amd2",
    "stanley-arm1",
    "toby-gcp1",
  ]
}

locals {
  tailscale_tailnet_id = "TwTN7rPx4921CNTRL"
}
