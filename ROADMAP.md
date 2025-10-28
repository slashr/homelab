# Homelab Development Roadmap

This document tracks all planned work, active projects, and their implementation details.
Each project is broken down into manageable PRs with clear scope, testing, and verification steps.

📝 **See [COMPLETED.md](COMPLETED.md) for historical record of finished PRs.**

⚙️ **See [.cursorrules](.cursorrules) for PR workflow, Codex review process, and branch management guidelines.**

---

## Active Roadmap

All planned PRs are listed below in logical execution order.

### Documentation & Knowledge Management

- [ ] **PR #19: Add Backup and Restore Documentation** 📚
  - **Priority:** High | **Effort:** Low (1-2 hours)
  - Create `docs/BACKUP_RESTORE.md` with procedures for:
    - Tailscale ACL backup/restore (including 10.42.0.0/16 Pod IP auto-approve)
    - Ansible Vault password recovery
    - kubeconfig backup/restore from michael-pi
    - Oracle Reserved IP (130.61.64.164 with prevent_destroy)
    - Critical GitHub Secrets inventory
  - Add "Disaster Recovery" section to README.md
  - **Test:** Follow docs in test scenario, verify configs can be restored

- [ ] **PR #20: Document Oracle Free Tier Resource Limits** 📝
  - **Priority:** Low | **Effort:** Low (1 hour)
  - Create `docs/ORACLE_FREE_TIER.md` documenting:
    - Current usage: AMD (2/2 FULL), ARM (2/4 OCPUs, 24/24 GB FULL)
    - ARM instance 30-day trial lifecycle
    - What happens when capacity limits are hit
  - Add monitoring script: `scripts/check-oracle-capacity.sh`
  - Link from README.md and AGENTS.md
  - **Test:** Verify current usage matches documentation

### Infrastructure Refactoring

- [ ] **PR #21: Standardize Oracle Server Naming Convention** 🏷️
  - **Priority:** Medium | **Effort:** Low (1 hour)
  - Update `oracle/servers.tf`: Rename `amd1/amd2/arm1/arm2` → `pam-amd1/angela-amd2/stanley-arm1/phyllis-arm2`
  - Update `moved` blocks to preserve Terraform state
  - Align with Ansible inventory and k3s labels (consistency across all tools)
  - **Test:** `terraform plan` shows only renaming (no destroy/recreate)

- [ ] **PR #22: Standardize UFW Variable Names Across Groups** 🔧
  - **Priority:** Low | **Effort:** Low (30 minutes)
  - Move common variables to `ansible/group_vars/all.yml`:
    - `tailscale_network_cidr: "100.100.0.0/16"`
    - `vpn_gateway_ip: "100.100.1.100"`
  - Keep group-specific in respective files (e.g., `local_network_cidr` in pis.yml only)
  - Remove duplicate definitions
  - **Test:** Run both playbooks, verify no variable resolution errors

### CI/CD Improvements

- [ ] **PR #23: Add k3s Playbook Dry-Run Validation** ✅
  - **Priority:** Medium | **Effort:** Low (1 hour)
  - Add to `.github/workflows/actions.yml` (around line 270):
    - `ansible-playbook --check` for k3s.yml on PRs
    - Include `k3s-master-config.yaml` in paths filter
  - Consistent with existing vpn.yml and pis.yml validation
  - **Test:** Create PR with k3s syntax error → CI catches it

- [ ] **PR #24: Optimize GitHub Actions Caching Strategy** 🚀
  - **Priority:** Low | **Effort:** Low (1 hour)
  - Better Terraform cache key: `${{ hashFiles('**/*.tf') }}` (include all dirs)
  - Add Ansible collections cache: `~/.ansible/collections`
  - Cache key: `${{ hashFiles('ansible/requirements.yml') }}`
  - Expected: 20-30% faster CI runs
  - **Test:** Compare CI run times before/after

- [ ] **PR #25: Add Pre-commit Hook for Sensitive File Detection** 🔒
  - **Priority:** Medium | **Effort:** Low (1 hour)
  - Update `.pre-commit-config.yaml`:
    - Add `detect-secrets` hook with baseline
    - Add custom `check-ansible-vault` hook
  - Create `scripts/check-vault-encrypted.sh` to verify vault files are encrypted
  - Prevent accidental commit of decrypted vault files
  - **Test:** Try committing unencrypted file → blocked

### Monitoring & Observability

- [ ] **PR #26: Add Health Checks and Status Dashboard** 📊
  - **Priority:** Medium | **Effort:** Medium (3-4 hours)
  - Create `ansible/playbooks/health-check.yml`:
    - UFW status, fail2ban banned IPs, Tailscale connectivity
    - k3s/k3s-agent service status, disk/memory usage
    - System uptime
  - Add `scripts/cluster-status.sh` wrapper with traffic light status
  - **Test:** Run on healthy cluster → all green; simulate issues → warnings

- [ ] **PR #27: Add Tailscale VPN Status Monitoring** 🔍
  - **Priority:** Medium | **Effort:** Medium (2-3 hours)
  - Create `ansible/roles/monitoring/tasks/tailscale-check.yml`
  - Script: `/usr/local/bin/tailscale-health-check.sh`
    - Check Tailscale service, ping michael-pi & pam-amd1
    - Verify latency < 100ms
  - Add cron job: `*/5 * * * *` (every 5 minutes)
  - Deploy via `ansible/playbooks/monitoring.yml`
  - **Test:** Stop Tailscale → health check logs error

### Data Protection

- [ ] **PR #28: Add Terraform State Backup Automation** 💾
  - **Priority:** High | **Effort:** Medium (2-3 hours)
  - Create `.github/workflows/backup-terraform-state.yml`
  - Weekly backup (Sundays 3 AM UTC) of all TF Cloud workspaces
  - Encrypt with GPG key (stored in GitHub Secrets)
  - Commit to private backup branch
  - Create `docs/TERRAFORM_STATE_RECOVERY.md` with restore procedure
  - **Test:** Manual trigger → verify encrypted state files created

---

## Quick Reference

```bash
# Raspberry Pi configuration
ansible-playbook -i ansible/hosts.ini ansible/playbooks/pis.yml
ansible-playbook -i ansible/hosts.ini ansible/playbooks/pis.yml --limit jim-pi
ansible-playbook -i ansible/hosts.ini ansible/playbooks/pis.yml --tags wifi

# Public nodes security hardening
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml --limit toby-gcp1
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml --tags fail2ban

# Check banned IPs
ansible public_nodes -i ansible/hosts.ini -b -a "fail2ban-client status sshd"

# Drift detection
ansible-playbook -i ansible/hosts.ini ansible/playbooks/pis.yml --check --diff
```

---

## Summary Statistics

**Active PRs:** 10  
**Completed PRs:** 16 (see [COMPLETED.md](COMPLETED.md))

**Breakdown by Category:**

- Documentation: 2 PRs
- Refactoring: 2 PRs
- CI/CD: 3 PRs
- Monitoring: 2 PRs
- Data Protection: 1 PR

**Total Estimated Effort:** 12-16 hours
