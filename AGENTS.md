# Homelab Repository Guide

## Project Overview

This repository codifies a hybrid homelab that spans Oracle Cloud, Google Cloud, and Raspberry Pis. Infrastructure is provisioned with Terraform, and post-provisioning configuration is handled with Ansible playbooks. High-level architecture and operational expectations are documented in `README.md`—start there for context on components and roadmap items.【F:README.md†L12-L88】

## Repository Layout

- `ansible/` — Playbooks for VPN and k3s lifecycle management, inventory files, and encrypted configuration snippets. Vault-managed files under `ansible/confs/` must be decrypted before editing and re-encrypted afterward.【F:ansible/README.md†L1-L10】【F:ansible/k3s.yml†L1-L130】【F:ansible/vpn.yml†L1-L88】
- `oracle/` — Terraform stack that stands up Oracle Cloud networking and compute. Relies on sensitive tenancy credentials and provisions both the network (VCN, security lists, reserved IP) and worker nodes.【F:oracle/provider.tf†L1-L18】【F:oracle/vcn.tf†L1-L71】【F:oracle/servers.tf†L1-L120】
- `gcp/` — Terraform configuration for a small GCP worker VM with customizable SSH metadata.【F:gcp/provider.tf†L1-L14】【F:gcp/compute.tf†L1-L24】
- `kubernetes/` — Terraform Cloud workspace that installs cluster add-ons (cert-manager, external-dns, Argo CD) via the shared Helm modules in `terraform-modules/`. Requires base64-encoded kubeconfig material and Cloudflare secrets.【F:kubernetes/provider.tf†L1-L47】【F:kubernetes/cluster.tf†L1-L16】【F:kubernetes/variables.tf†L1-L33】
- `terraform-modules/` — Reusable Helm-based add-ons (cert-manager, external-dns, Argo CD, ingress-nginx, MetalLB). Each module manages its own namespace and supporting secrets.【F:terraform-modules/cert-manager/cert-manager.tf†L1-L49】【F:terraform-modules/external-dns/external-dns.tf†L1-L34】【F:terraform-modules/argo-cd/argo-cd.tf†L1-L34】【F:terraform-modules/ingress-nginx/ingress-nginx.tf†L1-L15】【F:terraform-modules/metallb/metallb.tf†L1-L14】
- `archive/` — Legacy assets kept for reference; do not assume they are current.

## Secrets and Environment Requirements

- Terraform stacks depend on Terraform Cloud workspaces keyed off tags (`oracle`, `gcp`, `dev`) and expect credentials/variables to be injected there. Do **not** hard-code secrets in source control.【F:oracle/provider.tf†L1-L15】【F:kubernetes/provider.tf†L1-L24】
- The Ansible playbooks rely on environment variables for sensitive values (for example `TAILSCALE_JOIN_KEY`) and on vault-encrypted files for firewall rules. Respect the existing patterns when introducing new secrets.【F:ansible/k3s.yml†L45-L84】【F:ansible/vpn.yml†L49-L73】

## Coding & Style Guidelines

- Follow the prevailing formatting: two-space indentation for YAML and Terraform HCL, and keep resources declarative. When adding Kubernetes manifests through Terraform, prefer `templatefile`/`yamldecode` patterns already in use.【F:terraform-modules/cert-manager/cert-manager.tf†L15-L34】【F:ansible/k3s.yml†L1-L130】
- Keep inventory and variable files organized by host groups; reuse the existing group vars model when adding new inventory data.【F:ansible/hosts.ini†L1-L18】【F:ansible/group_vars/all.yml†L1-L5】
- Modules should be reusable: expose knobs via `variables.tf` and avoid hard-coded credentials or environment-specific values unless explicitly part of the architecture.【F:terraform-modules/cert-manager/variables.tf†L1-L27】【F:terraform-modules/external-dns/variables.tf†L1-L3】

## Testing & Validation

- Run `pre-commit run --all-files` before committing to lint Terraform, Ansible, and YAML sources as documented in the contribution guidelines.【F:README.md†L96-L104】
- For Terraform-heavy changes, execute `terraform init`/`terraform plan` against the relevant stack when feasible; otherwise, document any cloud-side blockers. Respect Terraform Cloud as the authoritative execution environment.
- For Ansible updates, validate playbooks with `ansible-lint` and (when possible) `ansible-playbook --check` against a controlled inventory to avoid disruptive changes.

## Operational Tips

- When modifying VPN firewall rules, decrypt `ansible/confs/iptables.conf`, edit, and re-encrypt to keep Git history clean. Double-check handlers that reload iptables to ensure they align with any new files.【F:ansible/README.md†L1-L9】【F:ansible/vpn.yml†L1-L34】
- Maintain the orchestrated deployment order: cert-manager → external-dns → Argo CD, matching the dependency chain encoded in Terraform modules and root stack. Update dependencies if module relationships change.【F:kubernetes/cluster.tf†L1-L16】
- Use Renovate configuration as reference for dependency grouping. When bumping versions manually, mirror the semantic commit conventions (`chore(deps): ...`).【F:renovate.json†L1-L87】
