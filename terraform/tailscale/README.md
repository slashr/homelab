# Tailscale ACL via Terraform

This module applies the Tailscale ACL policy defined in `terraform/tailscale/acl.json` using the Tailscale Terraform provider.

## Inputs

* `tailscale_api_key` (sensitive): Tailscale API key with ACL edit permission.

## Files

* `terraform/tailscale/acl.json`: Source ACL policy applied to the tailnet.

## Usage

State is stored in Terraform Cloud (`formcloud`) using a workspace tagged `tailscale` (execution mode: local/CLI-driven, like the other stacks).
Ensure that workspace exists and has `TS_API_KEY` (or set via CLI) before running.

Run in `terraform/tailscale`:

```bash
terraform init
terraform plan -var="tailscale_api_key=..."
terraform apply -var="tailscale_api_key=..."
```

Store the API key securely (e.g., Terraform Cloud variable or CI secret).
