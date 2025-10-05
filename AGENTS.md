# Homelab Repository Guide

## Project Overview

This repository codifies a hybrid homelab that spans Oracle Cloud, Google Cloud, and Raspberry Pis. Infrastructure is provisioned with Terraform, and post-provisioning configuration is handled with Ansible playbooks. High-level architecture and operational expectations are documented in `README.md`—start there for context on components and roadmap items.

## Repository Layout

- `ansible/` — Playbooks for VPN and k3s lifecycle management, inventory files, and encrypted configuration snippets. Vault-managed files under `ansible/confs/` must be decrypted before editing and re-encrypted afterward.
- `oracle/` — Terraform stack that stands up Oracle Cloud networking and compute. Relies on sensitive tenancy credentials and provisions both the network (VCN, security lists, reserved IP) and worker nodes.
- `gcp/` — Terraform configuration for a small GCP worker VM with customizable SSH metadata.
- `kubernetes/` — Terraform Cloud workspace that installs cluster add-ons (cert-manager, external-dns, Argo CD) via the shared Helm modules in `terraform-modules/`. Requires base64-encoded kubeconfig material and Cloudflare secrets.
- `terraform-modules/` — Reusable Helm-based add-ons (cert-manager, external-dns, Argo CD, ingress-nginx, MetalLB). Each module manages its own namespace and supporting secrets.
- `.github/workflows/` — CI/CD workflows for infrastructure deployment (`actions.yml`) and security scanning (`security.yml`).
- `.github/actions/` — Reusable composite actions for common workflow tasks (SSH setup, pre-commit).
- `archive/` — Legacy assets kept for reference; do not assume they are current.

## Git Ignore Patterns

The `.gitignore` prevents sensitive and generated files from being committed:
- `*.tfstate*` — Terraform state files (managed remotely in Terraform Cloud)
- `*.tfvars` — Variable files that may contain secrets
- `*.pem` — Private key files
- `.terraform/` — Terraform provider caches
- `.terraformrc` / `terraform.rc` — Local Terraform configuration

## GitHub Actions Workflows

### Main Deployment Workflow (`actions.yml`)

The primary deployment workflow orchestrates infrastructure provisioning and configuration across all environments. It runs on pushes to `main`/`staging`, pull requests, and manual triggers.

**Job Execution Order:**
1. **gcp-setup** & **oracle-setup** (parallel) — Provision cloud infrastructure
2. **tailscale-setup** — Configure VPN mesh network between all nodes
3. **k3s-setup** — Deploy and configure Kubernetes cluster (only on `main` push or manual trigger)
4. **run-k3s** — Deploy cluster add-ons via Terraform

**Key Features:**
- Concurrency control prevents conflicting deployments (`cancel-in-progress: false`)
- Comprehensive caching for Terraform plugins, pip packages, pre-commit hooks, and Ansible collections
- Terraform Cloud integration for remote state management (workspace tags: `oracle`, `gcp`, `dev`)
- Pre-commit hooks run only on changed files in PRs for efficiency
- 30-45 minute timeouts prevent hanging jobs
- Drift detection on `main` branch post-apply
- Step summaries provide deployment status visibility

### Security Scanning Workflow (`security.yml`)

Automated security scanning runs on merge to `main`, daily at 2 AM UTC, and on manual trigger. Scans skip for documentation-only changes (`**.md`, `LICENSE`, `AGENTS.md`, `archive/**`).

**Security Jobs:**
1. **security-scan** — Trivy vulnerability scanning (filesystem + Terraform config) with SARIF uploads to GitHub Security tab
2. **secret-scan** — TruffleHog secret detection with full history scan
3. **security-summary** — Consolidated status report with links to Security tab

**Scanning Strategy:**
- **Main only:** Scans run after merge to main, not on PRs (faster PR feedback, reduced costs)
- **Comprehensive:** Full history scans with complete vulnerability and secret detection
- **Scheduled:** Daily scans at 2 AM UTC catch new vulnerabilities in dependencies
- **Manual:** Workflow dispatch available for ad-hoc security checks
- **Verified only:** TruffleHog reports only verified secrets to reduce noise
- **SARIF uploads:** Results visible in GitHub Security tab for tracking

## Composite Actions

### `.github/actions/setup-precommit/`
Reusable action that installs pre-commit, caches environments, and runs checks on changed files. Automatically detects PR vs push context to determine the correct base commit for diff calculation.

### `.github/actions/setup-ssh/`
Configures SSH authentication with private key and disables strict host checking. Optionally sets up Ansible Vault password file when provided.

**Inputs:**
- `ssh_private_key` (required) — SSH private key for server authentication
- `ansible_vault_password` (optional) — Vault password for decrypting encrypted Ansible files

## Secrets and Environment Requirements

### GitHub Actions Secrets (Required)

**Terraform Cloud:**
- `TF_API_TOKEN` — Terraform Cloud API token for workspace management

**Oracle Cloud Infrastructure:**
- `TF_USER_OCID` — Oracle user OCID
- `TF_TENANCY_OCID` — Oracle tenancy OCID
- `TF_OCI_PRIVATE_KEY` — Oracle API private key (PEM format)
- `TF_FINGERPRINT` — Oracle API key fingerprint
- `TF_COMPARTMENT_ID` — Oracle compartment ID
- `TF_SSH_AUTHORIZED_KEYS` — Public SSH keys for instance access

**Google Cloud Platform:**
- `GCP_CREDENTIALS` — GCP service account credentials (JSON format)

**Kubernetes:**
- `TF_KUBE_CLIENT_CERT` — Base64-encoded kubeconfig client certificate
- `TF_KUBE_CLIENT_KEY` — Base64-encoded kubeconfig client key

**Cloudflare:**
- `TF_CLOUDFLARE_API_TOKEN` — API token with DNS permissions for cert-manager and external-dns

**Tailscale VPN:**
- `TAILSCALE_CLIENT_ID` — OAuth client ID for GitHub Actions runner
- `TAILSCALE_CLIENT_SECRET` — OAuth client secret for GitHub Actions runner
- `TAILSCALE_JOIN_KEY` — Auth key for node registration (used by Ansible)

**Ansible:**
- `SSH_AUTH_PRIVATE_KEY` — SSH private key for accessing all managed nodes
- `ANSIBLE_VAULT_PASSWORD` — Password for decrypting vault-encrypted configuration files

### Terraform Cloud Workspaces

Terraform stacks depend on Terraform Cloud workspaces keyed off tags (`oracle`, `gcp`, `dev`) and expect credentials/variables to be injected there. Do **not** hard-code secrets in source control.

### Environment Variables

- `TAILSCALE_JOIN_KEY` — Required by Ansible playbooks for k3s VPN integration
- `GOOGLE_CREDENTIALS` — Set in workflow environment for GCP provider authentication

## Ansible Configuration

### Inventory Structure

The `ansible/hosts.ini` defines host groups:
- `vpn` — Oracle VPN gateway (pam-amd1)
- `pi_workers` — Raspberry Pi worker nodes (jim-pi, dwight-pi)
- `oracle_workers` — Oracle worker nodes (pam-amd2, pam-arm1, pam-arm2)
- `gcp_workers` — GCP worker nodes
- `pihole_worker` — Pi-hole DNS server (dwight-pi)
- `michael-pi` — k3s master node

Variables are managed in `ansible/group_vars/all.yml` and define cluster-wide settings like k3s version and master node details.

### Vault-Encrypted Files

Files in `ansible/confs/` are encrypted with ansible-vault (password stored in Bitwarden and GitHub Secrets). These contain sensitive firewall rules and network configuration.

**Encryption/Decryption Workflow:**
```bash
# Decrypt
ansible-vault decrypt confs/iptables.conf

# Make changes
vim confs/iptables.conf

# Re-encrypt
ansible-vault encrypt confs/iptables.conf
```

**Important:** Always re-encrypt files before committing. Update `ANSIBLE_VAULT_PASSWORD` secret if changing the vault password.

### Playbook Execution

**vpn.yml** — Configures Tailscale mesh VPN across all nodes and sets up iptables forwarding on VPN gateway. Runs on every push after infrastructure provisioning.

**k3s.yml** — Deploys k3s master on `michael-pi` and joins worker nodes from Oracle, GCP, and remaining Raspberry Pis. Only runs on `main` push or manual workflow dispatch. Integrates Tailscale for pod-to-pod networking using the `--vpn-auth` flag.

## Kubernetes Deployment

### Module Dependencies

Terraform modules in `kubernetes/cluster.tf` have explicit dependency ordering:
```
cert-manager (first)
    ↓
external-dns (depends on cert-manager)
    ↓
argo-cd (depends on cert-manager + external-dns)
```

This ensures certificate management is ready before DNS automation and GitOps tooling.

### Provider Configuration

Kubernetes providers connect to the k3s master at `130.61.64.164:6443` (Oracle reserved public IP) rather than Tailscale IPs because Terraform Cloud runners cannot access the mesh network. Authentication uses base64-decoded client certificates.

### Add-on Modules

- **cert-manager** — Automates TLS certificate provisioning with Let's Encrypt
- **external-dns** — Syncs Kubernetes services/ingresses to Cloudflare DNS
- **argo-cd** — GitOps continuous delivery with app-of-apps pattern
- **ingress-nginx** — HTTP(S) ingress controller (optional, Traefik used by default)
- **metallb** — Bare-metal load balancer (optional)

## Coding & Style Guidelines

- Follow the prevailing formatting: two-space indentation for YAML and Terraform HCL, and keep resources declarative.
- When adding Kubernetes manifests through Terraform, prefer `templatefile`/`yamldecode` patterns already in use.
- Keep inventory and variable files organized by host groups; reuse the existing group vars model when adding new inventory data.
- Modules should be reusable: expose knobs via `variables.tf` and avoid hard-coded credentials or environment-specific values unless explicitly part of the architecture.
- Use descriptive resource names and add comments for complex logic.

## Testing & Validation

### Pre-commit Hooks

Run `pre-commit run --all-files` before committing to lint Terraform, Ansible, and YAML sources. Hooks are configured in `.pre-commit-config.yaml`:
- `terraform_fmt` — Format Terraform files
- `terraform_validate` — Validate Terraform configuration syntax
- `ansible-lint` — Lint Ansible playbooks
- `yamllint` — Lint YAML files (200 char line limit)

**Installation:**
```bash
pip install pre-commit
pre-commit install
```

### Terraform Validation

For Terraform-heavy changes, execute `terraform init`/`terraform plan` against the relevant stack when feasible; otherwise, document any cloud-side blockers. Respect Terraform Cloud as the authoritative execution environment.

### Ansible Validation

For Ansible updates, validate playbooks with `ansible-lint` and (when possible) `ansible-playbook --check` against a controlled inventory to avoid disruptive changes.

## Dependency Management

### Renovate Bot

Automated dependency updates are managed by Renovate (config: `renovate.json`). Dependencies are grouped by type:
- Terraform Providers
- Helm Charts
- Ansible Collections
- GitHub Actions
- Python Dependencies
- Pre-commit Hooks

**Schedule:** Weekly on Mondays before 6 AM UTC  
**Rate Limits:** 5 concurrent PRs, 2 PRs per hour  
**Commit Convention:** `chore(deps): ...` (semantic commits enabled)  
**Vulnerability Alerts:** Enabled with `security` + `dependencies` labels  
**Automerge:** Disabled (requires manual review)

### Manual Updates

When bumping versions manually, mirror the semantic commit conventions used by Renovate (`chore(deps): update X to vY.Z`).

## Operational Tips

### VPN Firewall Rules

When modifying VPN firewall rules, decrypt `ansible/confs/iptables.conf`, edit, and re-encrypt to keep Git history clean. Double-check handlers that reload iptables to ensure they align with any new files.

### Module Deployment Order

Maintain the orchestrated deployment order: cert-manager → external-dns → Argo CD, matching the dependency chain encoded in Terraform modules and root stack. Update dependencies if module relationships change.

### Workflow Debugging

- Check job summaries in GitHub Actions for high-level status
- Review step logs for detailed error messages
- For Terraform issues, inspect plan files uploaded as artifacts (available for 5 days on PRs)
- For drift detection, check the drift summary step on `main` branch runs
- Security findings are visible in the GitHub Security tab (SARIF uploads)

### Branch Strategy

- `main` — Production deployments (auto-applies Terraform)
- `staging` — Test branch (skips most jobs to save resources)
- Feature branches → PRs to `main` (plan-only, no apply)

### Tailscale Integration

Tailscale creates a mesh VPN across all nodes using tags (`tag:k3s`) and OAuth credentials. The `TAILSCALE_JOIN_KEY` is used by both Ansible playbooks and k3s itself (via `--vpn-auth` flag) to authenticate nodes and enable pod-to-pod networking across cloud providers and on-premises Raspberry Pis.

**Manual Tailscale Tasks (not yet automated):**
- Backup Access Control List including Pod IP auto-approve (`10.42.0.0/16`)
- Custom node IP range (`100.100.0.0/16`)
- Groups and tags definitions

## Network Architecture

### IP Address Ranges

**Oracle Cloud VCN:**
- CIDR Block: `10.0.0.0/16`
- Reserved Public IP: `130.61.64.164` (pam-amd1 / VPN gateway)

**Tailscale Mesh Network:**
- Node IP Range: `100.100.0.0/16`
- Pod IP Range (k3s): `10.42.0.0/16` (auto-approved in ACL)

**Raspberry Pi Local Network:**
- LAN Range: `192.168.1.0/24`
- Tailscale Range: `172.20.60.0/24`

**MetalLB Load Balancer:**
- IP Pool: `198.168.60.11/30` (for exposing services)

### Server Inventory

**Raspberry Pis (On-Premises):**
- `michael-pi` — k3s master node (Pi 5 8GB) — `192.168.1.100` / `100.100.1.100` (Tailscale)
- `jim-pi` — k3s worker (Pi 5 8GB) — `192.168.1.101` / `100.100.1.101` (Tailscale)
- `dwight-pi` — k3s worker + Pi-hole (Pi 4 8GB) — `192.168.1.102` / `100.100.1.102` (Tailscale)

**Oracle Cloud (Free Tier):**
- `pam-amd1` — VPN gateway (VM.Standard.E2.1.Micro: 1 CPU / 1GB RAM) — `130.61.64.164`
- `angela-amd2` — k3s worker (VM.Standard.E2.1.Micro) — `130.61.63.188`
- `stanley-arm1` — k3s worker (VM.Standard.A1.Flex: 1 OCPU / 6GB RAM) — `130.162.225.255`
- `phyllis-arm2` — k3s worker (VM.Standard.A1.Flex) — `138.2.130.168`

**Oracle Free Tier Limits:**
- 2 AMD Instances (VM.Standard.E2.1.Micro): 1 CPU / 1GB RAM / 50GB boot volume each
- 4 ARM Instances (VM.Standard.A1.Flex): 1 OCPU / 6GB RAM / 50GB boot volume each
- ARM instances are flexible shape and **not always free** — deleted after one-month trial
- Reserved public IP has `prevent_destroy = true` lifecycle rule to avoid accidental deletion

**Google Cloud Platform:**
- `toby-gcp1` — k3s worker — `34.28.187.2`

### Networking Components

- **Traefik** — Default k3s ingress controller and load balancer (replaces ingress-nginx + MetalLB for simplicity)
- **Tailscale** — Mesh VPN for secure node-to-node and pod-to-pod communication across clouds
- **WireGuard** — Legacy VPN (port 51820 exposed on Oracle VPN gateway, see archive)
- **iptables** — NAT and forwarding rules on VPN gateway (managed by Ansible)

## Troubleshooting

### Common Issues

**Terraform apply fails:**
- Verify all required secrets are set in Terraform Cloud workspace
- Check workspace tags match provider configuration
- Review cloud provider quotas/limits

**Ansible playbook fails:**
- Ensure Tailscale is connected (run `tailscale status` on nodes)
- Verify SSH keys are correct and have proper permissions
- Check Ansible Vault password is correct
- Confirm `TAILSCALE_JOIN_KEY` is set in environment

**k3s nodes not joining:**
- Check Tailscale connectivity between master and workers
- Verify k3s master is fully initialized before running worker join
- Review k3s-agent service logs: `journalctl -u k3s-agent -f`

**Security scans failing:**
- Ensure full history is fetched (`fetch-depth: 0`)
- TruffleHog errors: check `--only-verified` and `--debug` flags compatibility
- Trivy cache issues: re-run workflow to fetch fresh data
- SARIF upload failures: verify `security-events: write` permission is set

### Support Resources

- GitHub Actions logs and summaries
- Terraform Cloud run history
- Oracle/GCP/Cloudflare console for infrastructure state
- Tailscale admin panel for VPN status
- Bitwarden for secret recovery

## Security Best Practices

- **Never commit secrets** — Use GitHub Secrets and Terraform Cloud variables
- **Rotate credentials regularly** — Update secrets in GitHub and Terraform Cloud
- **Monitor security scan results** — Review SARIF uploads in GitHub Security tab
- **Encrypt sensitive configs** — Always use Ansible Vault for firewall rules and keys
- **Verify TLS certificates** — Let's Encrypt certs auto-renew via cert-manager
- **Audit access logs** — Review who accessed infrastructure via Tailscale and cloud provider logs
- **Keep dependencies updated** — Review and merge Renovate PRs weekly
