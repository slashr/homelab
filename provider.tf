terraform {
  cloud {
    organization = "formcloud"
    workspaces {
      tags = ["dev"]
    }
  }
  required_version = ">= 1.0"

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

provider "oci" {
  #  config_file_profile=var.config_file_profile
  user_ocid    = "ocid1.user.oc1..aaaaaaaah26k5uk5a54sbd232k3myniz6q2h3rn5gctdk6ohbp5znbkbgmaa"
  fingerprint  = "eb:35:e3:30:98:c3:8f:46:ab:55:08:ff:2f:43:47:61"
  tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaaqjhyb6c3f6ap2p4qai46qm7eeovunkwlaambama5h474yiamjsqq"
  region       = "eu-frankfurt-1"
  private_key  = base64decode(var.private_key)
}
