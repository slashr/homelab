output "cloudflare_tunnel_token" {
  description = "Token for cloudflared to authenticate with Cloudflare Tunnel"
  value       = module.cloudflare-tunnel.tunnel_token
  sensitive   = true
}

output "cloudflare_tunnel_id" {
  description = "ID of the Cloudflare Tunnel"
  value       = module.cloudflare-tunnel.tunnel_id
}
