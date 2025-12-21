moved {
  from = kubernetes_namespace.cert-manager
  to   = kubernetes_namespace_v1.cert-manager
}

moved {
  from = kubernetes_secret.cloudflare-api-token
  to   = kubernetes_secret_v1.cloudflare-api-token
}

resource "kubernetes_namespace_v1" "cert-manager" {
  metadata {
    name = var.namespace
  }
  lifecycle { # This is automatically populated by the cluster, and would otherwise create changes with each apply
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

resource "helm_release" "cert-manager" {
  chart      = "cert-manager"
  name       = "cert-manager"
  namespace  = var.namespace
  repository = "https://charts.jetstack.io"
  timeout    = var.timeout
  values     = [file("${path.module}/values.yaml")]
  version    = var.chart_version

  depends_on = [
    kubernetes_namespace_v1.cert-manager
  ]
}

# Provision the production ClusterIssuer once cert-manager is installed.
resource "kubernetes_manifest" "letsencrypt_prod_clusterissuer" {
  manifest = yamldecode(
    templatefile("${path.module}/clusterissuer-letsencrypt-prod.yaml", {
      email = var.letsencrypt_prod_email
    })
  )

  depends_on = [
    helm_release.cert-manager,
    kubernetes_secret_v1.cloudflare-api-token,
  ]
}

# Required for cert-manager to allow it to set dns records on cloudflare
resource "kubernetes_secret_v1" "cloudflare-api-token" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = "cert-manager"
  }

  data = {
    api-token = var.cloudflare_api_token
  }
  depends_on = [
    kubernetes_namespace_v1.cert-manager
  ]
}
