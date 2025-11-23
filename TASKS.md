# Homelab Task Tracker

This document tracks all planned work, active tasks, and their implementation details.
Each task is broken down into manageable PRs with clear scope, testing, and verification steps.

📝 **See [COMPLETED.md](COMPLETED.md) for historical record of finished PRs.**

⚙️ **See [.cursorrules](.cursorrules) for PR workflow, Codex review process, and branch management guidelines.**

---

## Active Tasks

All planned PRs are listed below in logical execution order.

### Documentation & Knowledge Management

* [ ] **PR #19: Add Backup and Restore Documentation** 📚
  * **Priority:** High
  * Create `docs/BACKUP_RESTORE.md` with procedures for:
    * Tailscale ACL backup/restore (including 10.42.0.0/16 Pod IP auto-approve)
    * Ansible Vault password recovery
    * kubeconfig backup/restore from michael-pi
    * Oracle Reserved IP (130.61.64.164 with prevent_destroy)
    * Critical GitHub Secrets inventory
  * Add "Disaster Recovery" section to README.md
  * **Test:** Follow docs in test scenario, verify configs can be restored

* [ ] **PR #20: Document Oracle Free Tier Resource Limits** 📝
  * **Priority:** Low
  * Create `docs/ORACLE_FREE_TIER.md` documenting:
    * Current usage: AMD (2/2 FULL), ARM (2/4 OCPUs, 24/24 GB FULL)
    * ARM instance 30-day trial lifecycle
    * What happens when capacity limits are hit
  * Add monitoring script: `scripts/check-oracle-capacity.sh`
  * Link from README.md and AGENTS.md
  * **Test:** Verify current usage matches documentation

* [ ] **PR #29: Cleanup Markdown and Remove MD013 Disables** 🧹
  * **Priority:** Medium
  * Reflow long lines and fix list spacing/fenced code languages across `AGENTS.md`, `PLANS.md`, and `terraform-modules/**/README.md`.
  * Remove `<!-- markdownlint-disable MD013 -->` where possible once lines are wrapped.
  * **Test:** `pre-commit run markdownlint --all-files` passes; Codacy markdownlint clean.

* [ ] **PR #31: Standardize Terraform Module READMEs** 📑
  * **Priority:** Low
  * Align headings, bullets, and fenced code languages across `terraform-modules/**/README.md`.
  * Add a short module index/table to `terraform-modules/README.md` linking to each submodule.
  * **Test:** `pre-commit run markdownlint --files terraform-modules/README.md terraform-modules/*/README.md`.

### Infrastructure Refactoring

* [ ] **PR #21: Standardize Oracle Server Naming Convention** 🏷️
  * **Priority:** Medium
  * Update `oracle/servers.tf`: Rename `amd1/amd2/arm1/arm2` → `pam-amd1/angela-amd2/stanley-arm1/phyllis-arm2`
  * Update `moved` blocks to preserve Terraform state
  * Align with Ansible inventory and k3s labels (consistency across all tools)
  * **Test:** `terraform plan` shows only renaming (no destroy/recreate)

* [ ] **PR #22: Standardize UFW Variable Names Across Groups** 🔧
  * **Priority:** Low
  * Move common variables to `ansible/group_vars/all.yml`:
    * `tailscale_network_cidr: "100.100.0.0/16"`
    * `vpn_gateway_ip: "100.100.1.100"`
  * Keep group-specific in respective files (e.g., `local_network_cidr` in pis.yml only)
  * Remove duplicate definitions
  * **Test:** Run both playbooks, verify no variable resolution errors

### CI & Tooling

* [ ] **PR #30: Add Docs-Only Lint Job to CI** 🧪
  * **Priority:** Low
  * Add a lightweight workflow/job to run `pre-commit run markdownlint --all-files` on PRs, including doc-only changes.
  * Ensure it skips heavy infra steps and reports status in PR checks.
  * **Test:** Open a doc-only PR and confirm the docs lint job runs and passes.

### Monitoring & Observability

* [ ] **PR #26: Add Health Checks and Status Dashboard** 📊
  * **Priority:** Medium
  * Create `ansible/playbooks/health-check.yml`:
    * UFW status, fail2ban banned IPs, Tailscale connectivity
    * k3s/k3s-agent service status, disk/memory usage
    * System uptime
  * Add `scripts/cluster-status.sh` wrapper with traffic light status
  * **Test:** Run on healthy cluster → all green; simulate issues → warnings

* [ ] **PR #27: Add Tailscale VPN Status Monitoring** 🔍
  * **Priority:** Medium
  * Create `ansible/roles/monitoring/tasks/tailscale-check.yml`
  * Script: `/usr/local/bin/tailscale-health-check.sh`
    * Check Tailscale service, ping michael-pi & pam-amd1
    * Verify latency < 100ms
  * Add cron job: `*/5 * * * *` (every 5 minutes)
  * Deploy via `ansible/playbooks/monitoring.yml`
  * **Test:** Stop Tailscale → health check logs error

### Data Protection

* [ ] **PR #28: Add Terraform State Backup Automation** 💾
  * **Priority:** High
  * Create `.github/workflows/backup-terraform-state.yml`
  * Weekly backup (Sundays 3 AM UTC) of all TF Cloud workspaces
  * Encrypt with GPG key (stored in GitHub Secrets)
  * Commit to private backup branch
  * Create `docs/TERRAFORM_STATE_RECOVERY.md` with restore procedure
  * **Test:** Manual trigger → verify encrypted state files created

### Raspberry Pi Maintenance

* _No active tasks._

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
**Completed PRs:** 19 (see [COMPLETED.md](COMPLETED.md))

**Breakdown by Category:**

* Documentation: 4 PRs
* Refactoring: 2 PRs
* CI & Tooling: 1 PR
* Monitoring: 2 PRs
* Data Protection: 1 PR
