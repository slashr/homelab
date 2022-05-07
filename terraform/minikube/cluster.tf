module "argo-cd" {
  source = "../modules/argo-cd"
}

module "ingress-nginx" {
  source = "../modules/ingress-nginx"
}
