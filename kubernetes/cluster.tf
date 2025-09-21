module "argo-cd" {
  source     = "../terraform-modules/argo-cd"
  depends_on = [module.cert-manager, module.external-dns]
}

module "cert-manager" {
  source               = "../terraform-modules/cert-manager"
  cloudflare_api_token = var.cloudflare_api_token

  # Ensure cert-manager is deployed first as it's often a dependency
  count = 1
}

resource "kubernetes_manifest" "letsencrypt_prod_clusterissuer" {
  manifest = yamldecode(templatefile("${path.module}/clusterissuer-letsencrypt-prod.yaml", {
    email = var.letsencrypt_prod_email
  }))

  depends_on = [module.cert-manager]
}

module "external-dns" {
  source               = "../terraform-modules/external-dns"
  cloudflare_api_token = var.cloudflare_api_token
  depends_on           = [module.cert-manager]
}
