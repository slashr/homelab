# Tailscale ACL via Terraform

This module applies the Tailscale ACL policy defined in `tailscale/acl.json` using the Tailscale Terraform provider.

## Inputs

* `tailscale_api_key` (sensitive): Tailscale API key with ACL edit permission.

## Files

* `tailscale/acl.json`: Source ACL policy applied to the tailnet.

## Usage

Run in `terraform/tailscale`:

```bash
terraform init
terraform plan -var="tailscale_api_key=..."
terraform apply -var="tailscale_api_key=..."
```

Store the API key securely (e.g., Terraform Cloud variable or CI secret).
