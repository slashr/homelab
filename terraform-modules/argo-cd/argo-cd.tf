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
              set -eu

              # Output non-encrypted yamls (recursive)
              find . -name '*.yaml' -type f | while read -r f; do
                case "$f" in
                  *.enc.yaml|*/kustomization.yaml|*/secret-generator.yaml) ;;
                  *) cat "$f"; echo "---" ;;
                esac
              done
              # Decrypt and output encrypted files via SOPS (recursive)
              find . -name '*.enc.yaml' -type f | while read -r f; do
                sops -d "$f"
                echo "---"
              done
        lockRepo: false
    EOF
  }

  depends_on = [
    kubernetes_namespace_v1.argo-cd
  ]
}

resource "kubernetes_secret_v1" "sops_age_key" {
  metadata {
    name      = "sops-age-key"
    namespace = kubernetes_namespace_v1.argo-cd.metadata[0].name
  }

  data = {
    "keys.txt" = var.sops_age_secret_key
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace_v1.argo-cd
  ]
}

resource "kubernetes_secret_v1" "github_repo_creds" {
  metadata {
    name      = "argocd-repo-creds-github-slashr"
    namespace = kubernetes_namespace_v1.argo-cd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    type     = "git"
    url      = "https://github.com/slashr"
    username = "slashr"
    password = var.github_token
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace_v1.argo-cd
  ]
}

resource "helm_release" "argo-cd" {
  name       = "argo-cd"
  namespace  = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "9.5.19"

  values = [templatefile("${path.module}/values.yaml", {})]

  depends_on = [
    kubernetes_namespace_v1.argo-cd,
    kubernetes_secret_v1.sops_age_key
  ]
}

resource "helm_release" "argo-cd-apps" {
  name       = "argo-cd-apps"
  namespace  = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.5"

  values = [templatefile("${path.module}/argo-cd-apps-values.yaml", {})]

  depends_on = [
    kubernetes_namespace_v1.argo-cd
  ]
}
