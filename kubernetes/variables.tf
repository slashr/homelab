variable "cloudflare_api_token" {
  type = string
}

# Raspberry Pi variables
variable "kube_client_cert" {
  description = "Rpi Kube cluster certificate base64 encoded"
  type        = string
}

variable "kube_client_key" {
  description = "Rpi Kube client key base64 encoded"
  type        = string
}
