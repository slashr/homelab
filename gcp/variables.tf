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

variable "ssh_username" {
  description = "Username for SSH login"
  type        = string
  default     = "dev"
}

variable "ssh_public_key" {
  description = "SSH public key for the instance"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ5Ysv6PF3HbWQ/JfP2vWEBHtH8wPv6ysbyosEREXpO3"
}

