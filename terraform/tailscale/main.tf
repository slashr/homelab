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
      version = "~> 0.24"
    }
  }
}

provider "tailscale" {
  api_key = var.tailscale_api_key
  tailnet = local.tailscale_tailnet_id
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
