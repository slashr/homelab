module "argo-cd" {
  source = "../modules/argo-cd"
}

module "ingress-nginx" {
  source = "../modules/ingress-nginx"
}

module "metallb" {
  source = "../modules/metallb"
}

module "cert-manager" {
  source = "../modules/cert-manager"
  cloudflare_api_token = var.cloudflare_api_token
}
