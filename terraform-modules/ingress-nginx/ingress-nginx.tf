moved {
  from = kubernetes_namespace.ingress-nginx
  to   = kubernetes_namespace_v1.ingress-nginx
}

resource "kubernetes_namespace_v1" "ingress-nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "~4.14.0"

  depends_on = [
    kubernetes_namespace_v1.ingress-nginx
  ]
}
