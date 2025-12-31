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
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

locals {
  # Use Tailscale IP for k8s API (requires local execution mode in Terraform Cloud)
  k8s_api_endpoint = "https://100.100.1.100:6443"
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

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
