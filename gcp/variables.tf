variable "project" {
  description = "GCP project to deploy resources"
  type        = string
  default     = "spice-385121"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-c"
}

variable "machine_type" {
  description = "Instance machine type"
  type        = string
  default     = "e2-micro"
}

