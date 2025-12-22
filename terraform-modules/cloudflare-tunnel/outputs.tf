output "tunnel_id" {
  description = "The ID of the Cloudflare Tunnel"
  value       = cloudflare_tunnel.homelab_ha.id
}

output "tunnel_name" {
  description = "The name of the Cloudflare Tunnel"
  value       = cloudflare_tunnel.homelab_ha.name
}

output "tunnel_token" {
  description = "The tunnel token for cloudflared authentication (use with 'cloudflared tunnel run --token')"
  value       = cloudflare_tunnel.homelab_ha.tunnel_token
  sensitive   = true
}

output "tunnel_cname" {
  description = "The CNAME target for DNS records"
  value       = "${cloudflare_tunnel.homelab_ha.id}.cfargotunnel.com"
}
