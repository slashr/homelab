module "argo-cd" {
  source     = "../terraform-modules/argo-cd"
  depends_on = [module.cert-manager]
}

module "cert-manager" {
  source                 = "../terraform-modules/cert-manager"
  cloudflare_api_token   = var.cloudflare_api_token
  letsencrypt_prod_email = var.letsencrypt_prod_email

  # Ensure cert-manager is deployed first as it's often a dependency
  count = 1
}

module "tailscale-operator" {
  source              = "../terraform-modules/tailscale-operator"
  oauth_client_id     = var.tailscale_oauth_client_id
  oauth_client_secret = var.tailscale_oauth_client_secret
}

module "cloudflare-tunnel" {
  source                = "../terraform-modules/cloudflare-tunnel"
  cloudflare_account_id = "0c9db0acdf0395f9fef4f94939f2b0c7"
  cloudflare_zone_id    = "a39b7d8ffa6518631ae4192c80ca4209"
  tunnel_name           = "homelab-ha"
  tunnel_hostnames      = ["*.shrub.dev"]
}

# Kubernetes secret for cloudflared running in-cluster
resource "kubernetes_namespace" "cloudflared" {
  metadata {
    name = "cloudflared"
    labels = {
      name = "cloudflared"
    }
  }
}

resource "kubernetes_secret" "cloudflared_tunnel" {
  metadata {
    name      = "cloudflared-tunnel"
    namespace = kubernetes_namespace.cloudflared.metadata[0].name
  }

  data = {
    token = module.cloudflare-tunnel.tunnel_token
  }

  type = "Opaque"
}
