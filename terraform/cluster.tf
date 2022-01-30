resource "kubernetes_namespace" "argo-cd" {
  metadata {
    name = "argo-cd"
  }
}
