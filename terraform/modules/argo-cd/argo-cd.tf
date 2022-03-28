resource "kubernetes_namespace" "argo-cd" {
  metadata {
    name = "argo-cd"
  }
}

resource "helm_release" "argo-cd" {
  name       = "argo-cd"
  namespace  = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "4.2.3"

  values = [templatefile("${path.module}/values.yaml",{})]

  depends_on = [
    resource.kubernetes_namespace.argo-cd
  ] 
}
