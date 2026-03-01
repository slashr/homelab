terraform {
  cloud {
    organization = "formcloud"
    workspaces {
      tags = ["tailscale"]
    }
  }

  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.28"
    }
  }
}

provider "tailscale" {
  oauth_client_id     = var.tailscale_oauth_client_id
  oauth_client_secret = var.tailscale_oauth_client_secret
  tailnet             = local.tailscale_tailnet_id
}

data "tailscale_device" "managed" {
  for_each = var.tailscale_device_hostnames
  hostname = each.key
  wait_for = "60s"
}

resource "tailscale_device_key" "managed" {
  for_each            = data.tailscale_device.managed
  device_id           = each.value.node_id
  key_expiry_disabled = true
}

resource "tailscale_acl" "this" {
  acl = file("${path.module}/acl.json")
}
