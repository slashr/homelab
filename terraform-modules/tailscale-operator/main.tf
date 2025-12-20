resource "kubernetes_namespace" "tailscale" {
  metadata {
    name = var.namespace
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

resource "helm_release" "tailscale_operator" {
  chart      = "tailscale-operator"
  name       = "tailscale-operator"
  namespace  = var.namespace
  repository = "https://pkgs.tailscale.com/helmcharts"
  timeout    = var.timeout
  version    = var.chart_version

  values = [
    yamlencode({
      oauth = {
        clientId     = var.oauth_client_id
        clientSecret = var.oauth_client_secret
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.tailscale
  ]
}
