terraform {
  cloud {
    organization = "formcloud"
    workspaces {
      tags = ["dev"]
    }
  }
  required_version = ">=1.9.0"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }
  }
}

locals {
  k8s_endpoint = "https://130.61.64.164:6443"
}

# Use a single provider configuration with locals
provider "kubectl" {
  host               = local.k8s_endpoint
  load_config_file   = false
  insecure           = "true"
  client_certificate = base64decode(var.kube_client_cert)
  client_key         = base64decode(var.kube_client_key)
}

provider "kubernetes" {
  host               = local.k8s_endpoint
  insecure           = "true"
  client_certificate = base64decode(var.kube_client_cert)
  client_key         = base64decode(var.kube_client_key)
}

provider "helm" {
  kubernetes {
    host               = local.k8s_endpoint
    insecure           = "true"
    client_certificate = base64decode(var.kube_client_cert)
    client_key         = base64decode(var.kube_client_key)
  }
}
