module "argo-cd" {
  source = "git::https://github.com/slashr/terraform-modules.git//argo-cd?ref=main"
}

module "cert-manager" {
  source               = "git::https://github.com/slashr/terraform-modules.git//cert-manager?ref=main"
  cloudflare_api_token = var.cloudflare_api_token
}

module "ingress-nginx" {
  source = "git::https://github.com/slashr/terraform-modules.git//ingress-nginx?ref=main"
}

module "metallb" {
  source = "git::https://github.com/slashr/terraform-modules.git//metallb?ref=main"
}

