resource "kubernetes_namespace" "external-dns" {
  metadata {
    name = "external-dns"
  }
}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  namespace  = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.16.0"

  values = [templatefile("${path.module}/values.yaml", {})]

  depends_on = [
    resource.kubernetes_namespace.external-dns
  ]
}

# Required for external-dns to allow it to set dns records on cloudflare
resource "kubernetes_secret" "cloudflare-api-token" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = "external-dns"
  }

  data = {
    api-token = var.cloudflare_api_token
  }
  depends_on = [
    kubernetes_namespace.external-dns
  ]
}
