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
  project = "spice-385121"
  region  = "us-central1"
}
