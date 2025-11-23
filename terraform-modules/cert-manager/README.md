# Cert-Manager Module

## Purpose

Deploys the cert-manager helm chart and sets up the production Let's Encrypt ClusterIssuer for obtaining TLS certificates. Also provisions a Cloudflare API token secret for DNS challenges.

## Required Variables

* `cloudflare_api_token` - API token with permissions to manage DNS records in Cloudflare.
* `letsencrypt_prod_email` - Email address to register with Let's Encrypt for the production ClusterIssuer.

## Example Usage

```hcl
module "cert-manager" {
  source               = "../terraform-modules/cert-manager"
  cloudflare_api_token = var.cloudflare_api_token
  letsencrypt_prod_email = var.letsencrypt_prod_email
}
```
