terraform {
  cloud {
    organization = "formcloud"
    workspaces {
      tags = ["gcp"]
    }
  }
  required_version = ">= 1.0"
}

provider "google" {
  project = var.project
  region  = var.region
}
