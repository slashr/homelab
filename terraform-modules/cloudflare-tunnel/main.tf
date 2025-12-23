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
        service  = "http://localhost:80"
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

  depends_on = [terraform_data.delete_existing_dns]
}

# Delete existing DNS records that conflict with tunnel CNAMEs
# This is needed because external-dns may have created A records
resource "terraform_data" "delete_existing_dns" {
  for_each = toset(var.tunnel_hostnames)

  # Re-run when tunnel ID changes (i.e., tunnel is recreated)
  triggers_replace = [cloudflare_zero_trust_tunnel_cloudflared.homelab_ha.id]

  provisioner "local-exec" {
    command = <<-EOT
      # Get existing record ID if any (excluding our own CNAME to the tunnel)
      TUNNEL_CNAME="${cloudflare_zero_trust_tunnel_cloudflared.homelab_ha.id}.cfargotunnel.com"
      RECORD=$(curl -s -X GET \
        "https://api.cloudflare.com/client/v4/zones/${var.cloudflare_zone_id}/dns_records?name=${each.value}" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json")

      RECORD_ID=$(echo "$RECORD" | jq -r '.result[0].id // empty')
      RECORD_CONTENT=$(echo "$RECORD" | jq -r '.result[0].content // empty')

      # Only delete if it's not already our tunnel CNAME
      if [ -n "$RECORD_ID" ] && [ "$RECORD_CONTENT" != "$TUNNEL_CNAME" ]; then
        echo "Deleting existing DNS record $RECORD_ID for ${each.value} (content: $RECORD_CONTENT)"
        curl -s -X DELETE \
          "https://api.cloudflare.com/client/v4/zones/${var.cloudflare_zone_id}/dns_records/$RECORD_ID" \
          -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
          -H "Content-Type: application/json"
      else
        echo "No conflicting DNS record found for ${each.value}"
      fi
    EOT
  }
}
