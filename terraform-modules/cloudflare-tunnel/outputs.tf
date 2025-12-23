output "tunnel_id" {
  description = "The ID of the Cloudflare Tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.homelab_ha.id
}

output "tunnel_name" {
  description = "The name of the Cloudflare Tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.homelab_ha.name
}

output "tunnel_token" {
  description = "The tunnel token for cloudflared authentication (use with 'cloudflared tunnel run --token')"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.homelab_ha.token
  sensitive   = true
}

output "tunnel_cname" {
  description = "The CNAME target for DNS records"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_ha.id}.cfargotunnel.com"
}
