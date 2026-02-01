variable "namespace" {
  description = "Namespace for MetalLB resources."
  type        = string
  default     = "metallb-system"
}

variable "chart_version" {
  description = "Helm chart version for MetalLB."
  type        = string
  default     = "~0.15.0"
}

variable "address_pool_cidr" {
  description = "MetalLB IPAddressPool CIDR for LoadBalancer addresses."
  type        = string
  default     = "192.168.60.11/30"
}
