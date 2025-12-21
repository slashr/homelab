resource "kubernetes_namespace_v1" "metallb" {
  metadata {
    name = "metallb"
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  namespace  = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "~0.15.0"

  depends_on = [
    kubernetes_namespace_v1.metallb
  ]
}
