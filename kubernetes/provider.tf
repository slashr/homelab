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
      version = ">= 3.0.1"
    }
  }
}

# Have to use Oracle 130.61.64.164 IP since Terraform Cloud needs it
# Otherwise could use Tailscale 100.100.1.100 IP
provider "kubectl" {
  host               = "https://130.61.64.164:6443"
  load_config_file   = false
  insecure           = "true"
  client_certificate = base64decode(var.kube_client_cert)
  client_key         = base64decode(var.kube_client_key)
}

provider "kubernetes" {
  host               = "https://130.61.64.164:6443"
  insecure           = "true"
  client_certificate = base64decode(var.kube_client_cert)
  client_key         = base64decode(var.kube_client_key)
}

provider "helm" {
  kubernetes = {
    host               = "https://130.61.64.164:6443"
    insecure           = "true"
    client_certificate = base64decode(var.kube_client_cert)
    client_key         = base64decode(var.kube_client_key)
  }
}
