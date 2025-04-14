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

module "external-dns" {
  source               = "../terraform-modules/external-dns"
  cloudflare_api_token = var.cloudflare_api_token
  depends_on           = [module.cert-manager]
}
