resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = var.namespace
  }
  lifecycle { # This is automatically populated by the cluster, and would otherwise create changes with each apply
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

resource "helm_release" "cert-manager" {
  chart      = "cert-manager"
  name       = "cert-manager"
  namespace  = var.namespace
  repository = "https://charts.jetstack.io"
  timeout    = var.timeout
  values     = [file("${path.module}/values.yaml")]
  version    = var.chart_version

  depends_on = [
    kubernetes_namespace.cert-manager,
    kubectl_manifest.cert-manager-crds #Because CRDs needs to be installed for the cert-manager Pods to be healthy and thus for the Helm release to succeed
  ]
}

resource "kubectl_manifest" "issuer-lets-encrypt-staging" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: akashon1@gmail.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
YAML
}

resource "kubectl_manifest" "issuer-lets-encrypt-prod" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: akashon1@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
YAML
}

#Get the data from the YAML file 
data "http" "cert_manager_crd_manifests" {
  url = "https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml"
}

#Convert the data into a kubectl_file_documents object
data "kubectl_file_documents" "cert_manager_crd_manifests" {
  content = data.http.cert_manager_crd_manifests.body
}

#Read the kubectl_file_documents object and apply it on the cluster
resource "kubectl_manifest" "cert-manager-crds" {
  for_each  = data.kubectl_file_documents.cert_manager_crd_manifests.manifests
  yaml_body = each.value

}


# Required for cert-manager to allow it to set dns records on cloudflare
resource "kubernetes_secret" "cloudflare-api-token" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = "cert-manager"
  }

  data = {
   api-token = var.cloudflare_api_token 
  }
  depends_on = [
    kubernetes_namespace.cert-manager
  ]
}
