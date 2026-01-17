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
# Namespace is created by ArgoCD (CreateNamespace=true in homelab-deployments)
resource "kubernetes_secret_v1" "cloudflared_tunnel" {
  metadata {
    name      = "cloudflared-tunnel"
    namespace = "cloudflared"
  }

  data = {
    token = module.cloudflare-tunnel.tunnel_token
  }

  type = "Opaque"
}

# Velero S3 credentials for OCI Object Storage backups
# Namespace is created by ArgoCD (CreateNamespace=true in homelab-deployments)
resource "kubernetes_secret_v1" "velero_credentials" {
  metadata {
    name      = "velero-s3-credentials"
    namespace = "velero"
  }

  data = {
    cloud = <<-EOF
      [default]
      aws_access_key_id=${var.velero_s3_access_key}
      aws_secret_access_key=${var.velero_s3_secret_key}
    EOF
  }

  type = "Opaque"
}

# OpenAI API key for homelab-map AI features
# Namespace is created by ArgoCD (homelab-deployments/src/homelab-map/namespace.yaml)
resource "kubernetes_secret_v1" "homelab_map_openai" {
  metadata {
    name      = "homelab-map-openai"
    namespace = "homelab-map"
  }

  data = {
    OPENAI_API_KEY = var.openai_api_key
  }

  type = "Opaque"
}

# Interactive password for homelab-map AI quote feature
resource "kubernetes_secret_v1" "homelab_map_interactive_password" {
  metadata {
    name      = "homelab-map-interactive-password"
    namespace = "homelab-map"
  }

  data = {
    INTERACTIVE_PASSWORD = var.homelab_map_interactive_password
  }

  type = "Opaque"
}
