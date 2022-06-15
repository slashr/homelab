provider "kubernetes" {
  config_path            = "~/.kube/cretus-config"
  config_context_cluster = "default"
}

provider "helm" {
  kubernetes {
    config_path            = "~/.kube/cretus-config"
    config_context_cluster = "default"
  }
}

