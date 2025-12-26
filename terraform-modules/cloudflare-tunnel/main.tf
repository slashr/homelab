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
resource "cloudflare_zero_trust_tunnel_cloudflared" "homelab_ha" {
  account_id    = var.cloudflare_account_id
  name          = var.tunnel_name
  tunnel_secret = random_id.tunnel_secret.b64_std
}

# Configure tunnel ingress rules
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab_ha" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab_ha.id

  config = {
    ingress = concat(
      [for hostname in var.tunnel_hostnames : {
        hostname = hostname
        service  = "http://traefik.kube-system.svc.cluster.local:80" # Traefik ClusterIP (cloudflared runs in-cluster)
      }],
      [{
        service = "http_status:404"
      }]
    )
  }
}

# Get the tunnel token for cloudflared authentication
data "cloudflare_zero_trust_tunnel_cloudflared_token" "homelab_ha" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab_ha.id
}

# Create CNAME DNS records pointing to the tunnel
resource "cloudflare_dns_record" "tunnel_cname" {
  for_each = toset(var.tunnel_hostnames)

  zone_id = var.cloudflare_zone_id
  name    = split(".", each.value)[0] # Extract subdomain (e.g., "argo" from "argo.shrub.dev")
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_ha.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1 # Auto TTL when proxied

  comment = "Managed by Terraform - Cloudflare Tunnel HA"
}
