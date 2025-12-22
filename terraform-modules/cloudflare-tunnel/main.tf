terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Generate a random secret for the tunnel
resource "random_id" "tunnel_secret" {
  byte_length = 32
}

# Create the Cloudflare Tunnel
resource "cloudflare_tunnel" "homelab_ha" {
  account_id = var.cloudflare_account_id
  name       = var.tunnel_name
  secret     = random_id.tunnel_secret.b64_std
}

# Configure tunnel ingress rules
resource "cloudflare_tunnel_config" "homelab_ha" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_tunnel.homelab_ha.id

  config {
    dynamic "ingress_rule" {
      for_each = var.tunnel_hostnames
      content {
        hostname = ingress_rule.value
        service  = "http://localhost:80"
      }
    }

    # Catch-all rule (required by Cloudflare)
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Create CNAME DNS records pointing to the tunnel
resource "cloudflare_record" "tunnel_cname" {
  for_each = toset(var.tunnel_hostnames)

  zone_id = var.cloudflare_zone_id
  name    = split(".", each.value)[0] # Extract subdomain (e.g., "argo" from "argo.shrub.dev")
  type    = "CNAME"
  content = "${cloudflare_tunnel.homelab_ha.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1 # Auto TTL when proxied

  comment = "Managed by Terraform - Cloudflare Tunnel HA"
}
