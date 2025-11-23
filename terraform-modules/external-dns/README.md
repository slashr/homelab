# External DNS Module

## Purpose

Installs ExternalDNS to manage DNS records for Kubernetes resources using Cloudflare.

## Required Variables

* `cloudflare_api_token` - API token allowing DNS record modifications.

## Example Usage

```hcl
module "external-dns" {
  source               = "../terraform-modules/external-dns"
  cloudflare_api_token = var.cloudflare_api_token
  depends_on           = [module.cert-manager]
}
```
