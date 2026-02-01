resource "kubernetes_namespace_v1" "metallb" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  namespace  = var.namespace
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = var.chart_version

  depends_on = [
    kubernetes_namespace_v1.metallb
  ]
}

resource "kubernetes_manifest" "metallb_address_pool" {
  manifest = yamldecode(
    templatefile("${path.module}/resources.yaml", {
      address_pool_cidr = var.address_pool_cidr,
      namespace         = var.namespace,
    })
  )

  depends_on = [
    helm_release.metallb
  ]
}
