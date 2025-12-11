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
      version = "~> 1.19.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1.0"
    }
  }
}

locals {
  # Use Oracle reserved public IP since Terraform Cloud runners cannot access Tailscale network
  # Alternative would be Tailscale IP: https://100.100.1.100:6443
  k8s_api_endpoint = "https://130.61.64.164:6443"
}

provider "kubectl" {
  host                   = local.k8s_api_endpoint
  load_config_file       = false
  client_certificate     = base64decode(var.kube_client_cert)
  client_key             = base64decode(var.kube_client_key)
  cluster_ca_certificate = base64decode(var.kube_cluster_ca_cert)
}

provider "kubernetes" {
  host                   = local.k8s_api_endpoint
  client_certificate     = base64decode(var.kube_client_cert)
  client_key             = base64decode(var.kube_client_key)
  cluster_ca_certificate = base64decode(var.kube_cluster_ca_cert)
}

provider "helm" {
  kubernetes = {
    host                   = local.k8s_api_endpoint
    client_certificate     = base64decode(var.kube_client_cert)
    client_key             = base64decode(var.kube_client_key)
    cluster_ca_certificate = base64decode(var.kube_cluster_ca_cert)
  }
}
