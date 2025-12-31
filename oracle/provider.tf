terraform {
  cloud {
    organization = "formcloud"
    workspaces {
      tags = ["oracle"]
    }
  }
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }
}

provider "oci" {
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  tenancy_ocid = var.tenancy_ocid
  region       = "eu-frankfurt-1"
  private_key  = base64decode(var.oci_private_key)
}

