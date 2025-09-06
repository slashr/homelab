// Creates the ServiceAccount used by GitHub Actions pipelines to interact with the cluster.
// A dedicated token Secret is also created so Terraform can surface the token and CA bundle
// as outputs (modern Kubernetes clusters no longer auto-create SA token secrets).

resource "kubernetes_service_account" "github_deployer" {
  metadata {
    name      = "github-deployer"
    namespace = "kube-system"
  }

  // ensure a token can be mounted if needed
  automount_service_account_token = true
}

// Grant cluster-admin (adjust if you want least privilege later)
resource "kubernetes_cluster_role_binding" "github_deployer_admin" {
  metadata {
    name = "github-deployer-admin"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.github_deployer.metadata[0].name
    namespace = kubernetes_service_account.github_deployer.metadata[0].namespace
  }
}

// Manually request a legacy token Secret so we can retrieve the bearer token via Terraform
resource "kubernetes_secret" "github_deployer_token" {
  metadata {
    name      = "github-deployer-token"
    namespace = kubernetes_service_account.github_deployer.metadata[0].namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.github_deployer.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

// Wait for the API server to populate the data fields in the secret and then read them
// (Terraform data source retries until the secret is populated).
data "kubernetes_secret" "github_deployer_token" {
  metadata {
    name      = kubernetes_secret.github_deployer_token.metadata[0].name
    namespace = kubernetes_secret.github_deployer_token.metadata[0].namespace
  }
  depends_on = [kubernetes_secret.github_deployer_token]
}

output "github_deployer_token" {
  description = "Bearer token for the github-deployer ServiceAccount (base64-decoded)"
  value       = base64decode(data.kubernetes_secret.github_deployer_token.data["token"])
  sensitive   = true
}

output "github_deployer_ca_cert" {
  description = "Cluster CA certificate bundle for the github-deployer token (base64 content)"
  value       = data.kubernetes_secret.github_deployer_token.data["ca.crt"]
  sensitive   = true
}
