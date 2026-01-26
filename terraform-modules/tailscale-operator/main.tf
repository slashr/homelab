resource "kubernetes_namespace_v1" "tailscale" {
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
      operatorConfig = {
        affinity = {
          nodeAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100
                preference = {
                  matchExpressions = [
                    {
                      key      = "kubernetes.io/hostname"
                      operator = "In"
                      values   = ["stanley-arm1"]
                    }
                  ]
                }
              }
            ]
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.tailscale
  ]
}
