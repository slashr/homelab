module "argo-cd" {
  source = "../terraform-modules/argo-cd"
}

module "cert-manager" {
  source               = "../terraform-modules/cert-manager"
  cloudflare_api_token = var.cloudflare_api_token
}

module "external-dns" {
  source               = "../terraform-modules/external-dns"
  cloudflare_api_token = var.cloudflare_api_token
}
