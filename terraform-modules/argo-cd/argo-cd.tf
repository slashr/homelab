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
  version    = "7.7.0"

  values = [templatefile("${path.module}/values.yaml", {})]

  depends_on = [
    resource.kubernetes_namespace.argo-cd
  ]
}

resource "helm_release" "argo-cd-apps" {
  name       = "argo-cd-apps"
  namespace  = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.2"

  values = [templatefile("${path.module}/argo-cd-apps-values.yaml", {})]

  depends_on = [
    resource.kubernetes_namespace.argo-cd
  ]
}
