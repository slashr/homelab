# Tailscale ACL via Terraform

This module applies the Tailscale ACL policy defined in `tailscale/acl.json` using the Tailscale Terraform provider.

## Inputs

* `tailscale_api_key` (sensitive): Tailscale API key with ACL edit permission.
* `tailscale_tailnet`: Tailnet ID.

## Files

* `tailscale/acl.json`: Source ACL policy applied to the tailnet.

## Usage

Run in `terraform/tailscale`:

```bash
terraform init
terraform plan -var="tailscale_api_key=..." -var="tailscale_tailnet=..."
terraform apply -var="tailscale_api_key=..." -var="tailscale_tailnet=..."
```

Store the API key securely (e.g., Terraform Cloud variable or CI secret).
