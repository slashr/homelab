module "argo-cd" {
  source = "git::https://github.com/slashr/terraform-modules.git//apps/argo-cd?ref=main"
}

# Disable and try and use traefik
# module "ingress-nginx" {
#   source = "git::https://github.com/slashr/terraform-modules.git//apps/ingress-nginx?ref=main"
# }

module "metallb" {
  source = "git::https://github.com/slashr/terraform-modules.git//apps/metallb?ref=main"
}

module "cert-manager" {
  source               = "git::https://github.com/slashr/terraform-modules.git//apps/cert-manager?ref=main"
  cloudflare_api_token = var.cloudflare_api_token
}
