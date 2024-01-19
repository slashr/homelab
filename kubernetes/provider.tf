terraform {
  cloud {
    organization = "formcloud"
    workspaces {
      tags = ["dev"]
    }
  }
  required_version = ">= 1.5"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

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
  kubernetes {
    host               = "https://130.61.64.164:6443"
    insecure           = "true"
    client_certificate = base64decode(var.kube_client_cert)
    client_key         = base64decode(var.kube_client_key)
  }
}
