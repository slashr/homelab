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

resource "tailscale_acl" "this" {
  acl = file("${path.module}/../../tailscale/acl.json")
}
