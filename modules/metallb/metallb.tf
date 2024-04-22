resource "kubernetes_namespace" "metallb" {
  metadata {
    name = "metallb"
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  namespace  = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "~0.13.10"

  depends_on = [
    resource.kubernetes_namespace.metallb
  ]
}
