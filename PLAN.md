# PLAN: Standardize Oracle Server Naming (PR #21)

## Objective

Align the Oracle Terraform stack with the hostnames already used by Ansible/k3s
(`pam-amd1`, `angela-amd2`, `stanley-arm1`, `phyllis-arm2`) so every tool refers to
the same names and Terraform keeps existing instances without reprovisioning.

## Steps

1. Update `oracle/servers.tf`:
   - Rename each `local.instances` key from `amd1/amd2/arm1/arm2` to the friendly names.
   - Update the existing `moved` blocks so any lingering single-resource state maps to
     the new keys, and add new `moved` blocks to remap current `instances["amd1"]`
     addresses to their renamed counterparts.
   - Ensure comments and any helper locals reference the new identifiers.
2. Adjust downstream references:
   - Update `oracle/vcn.tf` (and any other Terraform files) to read the renamed keys.
   - Refresh README or docs that still describe the old names so the narrative matches
     the infrastructure.
3. Run `terraform fmt oracle/servers.tf oracle/vcn.tf` to keep formatting tidy.

## Validation

- `terraform fmt` reports no diffs.
- (Best-effort) `terraform plan` would show only name updates with zero destroys; we
  cannot run it locally without OCI credentials, so note this limitation in the PR and
  rely on CI/Terraform Cloud for confirmation.
