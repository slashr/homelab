# Cert-Manager Module

## Purpose
Deploys the cert-manager helm chart and sets up Let's Encrypt issuers for obtaining TLS certificates. Also provisions a Cloudflare API token secret for DNS challenges.

## Required Variables
- `cloudflare_api_token` - API token with permissions to manage DNS records in Cloudflare.

## Example Usage
```hcl
module "cert-manager" {
  source               = "../terraform-modules/cert-manager"
  cloudflare_api_token = var.cloudflare_api_token
}
```
