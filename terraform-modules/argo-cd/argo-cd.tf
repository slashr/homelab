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
  version    = "6.7.11"

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
  version    = "1.4.1"

  values = [templatefile("${path.module}/argo-cd-apps-values.yaml", {})]

  depends_on = [
    resource.kubernetes_namespace.argo-cd
  ]
}
