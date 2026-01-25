resource "kubernetes_namespace_v1" "argo-cd" {
  metadata {
    name = "argo-cd"
  }
}

# ConfigMap for argocd-vault-plugin with SOPS support
resource "kubernetes_config_map_v1" "argocd_cmp" {
  metadata {
    name      = "argocd-cmp-cm"
    namespace = "argo-cd"
  }

  data = {
    "avp-sops.yaml" = <<-EOF
      apiVersion: argoproj.io/v1alpha1
      kind: ConfigManagementPlugin
      metadata:
        name: avp-sops
      spec:
        allowConcurrency: true
        discover:
          find:
            command:
              - sh
              - "-c"
              - "find . -name '*.enc.yaml' | head -1"
        generate:
          command:
            - sh
            - "-c"
            - |
              # Output non-encrypted yamls (recursive)
              find . -name '*.yaml' -type f | while read -r f; do
                case "$f" in
                  *.enc.yaml|*/kustomization.yaml|*/secret-generator.yaml) ;;
                  *) cat "$f"; echo "---" ;;
                esac
              done
              # Decrypt and output encrypted files via AVP (recursive)
              find . -name '*.enc.yaml' -type f | while read -r f; do
                argocd-vault-plugin generate "$f"
                echo "---"
              done
        lockRepo: false
    EOF
  }

  depends_on = [
    kubernetes_namespace_v1.argo-cd
  ]
}

resource "helm_release" "argo-cd" {
  name       = "argo-cd"
  namespace  = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "9.1.9"

  values = [templatefile("${path.module}/values.yaml", {})]

  depends_on = [
    kubernetes_namespace_v1.argo-cd
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
    kubernetes_namespace_v1.argo-cd
  ]
}
