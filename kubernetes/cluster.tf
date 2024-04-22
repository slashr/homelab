module "argo-cd" {
  source = "../modules/argo-cd"
}

module "cert-manager" {
  source               = "../modules/cert-manager"
  cloudflare_api_token = var.cloudflare_api_token
}

module "external-dns" {
  source               = "../modules/external-dns"
  cloudflare_api_token = var.cloudflare_api_token
}
