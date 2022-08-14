terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "kubectl" {
  config_path            = "~/.kube/cretus-config"
  config_context_cluster = "default"
}

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

