# Homelab Improvement Plan

This document outlines 10 small, manageable PRs to enhance the homelab infrastructure. Each PR is scoped for quick review and low-risk deployment.

---

## PR #1: Add Backup and Restore Documentation for Critical Configuration 📚

**Branch:** `docs/backup-restore-guide`  
**Priority:** High  
**Effort:** Low (1-2 hours)

### Problem

The README mentions manual Tailscale configuration (ACL, Pod IP ranges, Groups/Tags) that needs backup, but there's no documented procedure. If Tailscale config is lost, cluster networking breaks.

### Changes

- Create `docs/BACKUP_RESTORE.md` with procedures for:
  - Tailscale ACL backup/restore (including 10.42.0.0/16 Pod IP auto-approve)
  - Ansible Vault password recovery (currently only in Bitwarden)
  - kubeconfig backup/restore from michael-pi
  - Oracle Reserved IP documentation (130.61.64.164 has `prevent_destroy=true`)
  - Critical GitHub Secrets inventory list
- Add to README.md under "Disaster Recovery" section
- Reference from AGENTS.md Repository Guide section

### Benefits

- Faster disaster recovery
- Clear onboarding for new team members
- Reduced bus factor (knowledge not locked in one person's head)

### Test

- Follow documentation steps in a test scenario
- Verify all critical configs can be restored from backups

---

## PR #2: Standardize Oracle Server Naming Convention 🏷️

**Branch:** `refactor/standardize-server-names`  
**Priority:** Medium  
**Effort:** Low (1 hour)

### Problem

Inconsistent naming: Oracle servers are `amd1/amd2/arm1/arm2` in Terraform, but `pam-amd1/angela-amd2/stanley-arm1/phyllis-arm2` in Ansible inventory and k3s labels. This creates confusion.

### Changes

- **Option A (Recommended):** Update Terraform to use character names
  - `oracle/servers.tf`: Rename locals from `amd1/amd2/arm1/arm2` → `pam-amd1/angela-amd2/stanley-arm1/phyllis-arm2`
  - Update `moved` blocks to preserve state
  - Update `display_name` to use full character names
  
- **Option B:** Update Ansible/k3s to use technical names (less preferred, character names are more memorable)

### Benefits

- Consistency across all tools (Terraform, Ansible, kubectl)
- Easier troubleshooting (no mental translation needed)
- Better alignment with "The Office" theme

### Test

- `terraform plan` shows only renaming (no destroy/recreate)
- Verify `moved` blocks work correctly
- Ansible playbooks still connect to correct hosts

---

## PR #3: Add Health Checks and Status Dashboard 📊

**Branch:** `feat/health-checks-dashboard`  
**Priority:** Medium  
**Effort:** Medium (3-4 hours)

### Problem

No centralized way to check cluster health. Need to manually SSH to nodes and run commands to verify services are running.

### Changes

- Create `ansible/playbooks/health-check.yml` playbook:

  ```yaml
  # Checks per node:
  - UFW status and rule count
  - fail2ban status and banned IP count
  - Tailscale connectivity (ping michael-pi)
  - k3s/k3s-agent service status
  - Disk usage (warn if >80%)
  - Memory usage (warn if >90%)
  - System uptime
  ```

- Add `scripts/cluster-status.sh` wrapper script:

  ```bash
  #!/bin/bash
  # Runs health check playbook and formats output
  # Shows traffic light status: 🟢 Healthy | 🟡 Warning | 🔴 Critical
  ```

- Add to README.md "Quick Commands" section

### Benefits

- Quick cluster health overview in <30 seconds
- Early warning for resource exhaustion
- Useful for on-call troubleshooting

### Test

- Run on healthy cluster → all green
- Simulate issues (stop service, fill disk) → correct warnings

---

## PR #4: Add Ansible Dry-Run Validation for k3s Playbook ✅

**Branch:** `ci/k3s-dry-run-validation`  
**Priority:** Medium  
**Effort:** Low (1 hour)

### Problem

`.github/workflows/actions.yml` validates `vpn.yml` and `pis.yml` with `--check`, but `k3s.yml` (most critical playbook) has no dry-run validation in PRs.

### Changes

- Add to `.github/workflows/actions.yml` (around line 270):

  ```yaml
  - name: Validate k3s playbook (dry-run)
    if: |
      github.event_name == 'pull_request' &&
      needs.changes.outputs.ansible == 'true'
    run: |
      ansible-playbook -i ansible/hosts.ini ansible/k3s.yml \
        --check --diff \
        -e k3s_version=v1.31.2+k3s1 \
        -e TAILSCALE_JOIN_KEY=dummy_key_for_validation
    working-directory: ${{ github.workspace }}
  ```

- Update paths filter to include `k3s-master-config.yaml`

### Benefits

- Catch k3s playbook syntax errors before merge
- Reduce risk of cluster disruption
- Consistent validation across all playbooks

### Test

- Create PR with intentional k3s.yml syntax error → CI catches it
- Create PR with valid k3s.yml changes → CI passes

---

## PR #5: Add Monitoring for Tailscale VPN Status 🔍

**Branch:** `feat/tailscale-monitoring`  
**Priority:** Medium  
**Effort:** Medium (2-3 hours)

### Problem

VPN failures break k3s communication between nodes. Currently no automated monitoring for Tailscale connectivity between nodes.

### Changes

- Create `ansible/roles/monitoring/tasks/tailscale-check.yml`:

  ```yaml
  # Script: /usr/local/bin/tailscale-health-check.sh
  # Checks:
  # - Tailscale service running
  # - Can ping michael-pi (100.100.1.100)
  # - Can ping pam-amd1 (VPN gateway)
  # - Latency < 100ms
  # Logs to syslog with tag "tailscale-health"
  ```

- Add cron job: `*/5 * * * *` (every 5 minutes)
- Create Ansible playbook: `ansible/playbooks/monitoring.yml`
- Deploy to all nodes except michael-pi (monitoring from itself is pointless)

### Benefits

- Early detection of VPN issues
- Historical latency data in syslog
- Can correlate k3s failures with VPN problems

### Test

- Stop Tailscale on a node → health check logs error
- Verify cron job runs and logs are created
- Check syslog for "tailscale-health" entries

---

## PR #6: Optimize GitHub Actions Caching Strategy 🚀

**Branch:** `ci/optimize-caching`  
**Priority:** Low  
**Effort:** Low (1 hour)

### Problem

GitHub Actions caching is suboptimal:

- Terraform plugin cache key only includes `gcp/**/*.tf` (misses oracle/, kubernetes/)
- No cache for Ansible collections (downloaded on every run)
- Pre-commit cache could be shared across jobs

### Changes

- Update `.github/workflows/actions.yml`:

  ```yaml
  # Better Terraform cache key
  - name: Cache Terraform plugins
    uses: actions/cache@v4
    with:
      path: ~/.terraform.d/plugin-cache
      key: ${{ runner.os }}-terraform-${{ hashFiles('**/*.tf') }}
      restore-keys: |
        ${{ runner.os }}-terraform-
  
  # Add Ansible collections cache
  - name: Cache Ansible collections
    uses: actions/cache@v4
    with:
      path: ~/.ansible/collections
      key: ${{ runner.os }}-ansible-${{ hashFiles('ansible/requirements.yml') }}
      restore-keys: |
        ${{ runner.os }}-ansible-
  ```

### Benefits

- Faster CI runs (estimated 20-30% faster)
- Reduced network usage
- Lower GitHub Actions minutes consumption

### Test

- Check CI run times before/after
- Verify cache hit logs in GitHub Actions

---

## PR #7: Add Terraform State Backup Automation 💾

**Branch:** `feat/terraform-state-backup`  
**Priority:** High  
**Effort:** Medium (2-3 hours)

### Problem

Terraform state is in Terraform Cloud, but no automated backups. If TF Cloud has issues or accidental deletion, infrastructure is unrecoverable.

### Changes

- Create `.github/workflows/backup-terraform-state.yml`:

  ```yaml
  # Scheduled weekly (Sundays at 3 AM UTC)
  # Downloads state from Terraform Cloud workspaces:
  # - oracle, gcp, dev (kubernetes)
  # Encrypts with GPG key (stored in GitHub Secrets)
  # Commits to private backup branch
  ```

- Add `TF_API_TOKEN` permission check in workflow
- Create `docs/TERRAFORM_STATE_RECOVERY.md` with restore procedure
- Add encrypted GPG key to GitHub Secrets

### Benefits

- Protection against Terraform Cloud outages
- Recovery from accidental state deletion
- Version history of infrastructure changes

### Test

- Manually trigger workflow → verify encrypted state files created
- Test decryption and restore procedure

---

## PR #8: Add Resource Limits Documentation for Oracle Free Tier 📝

**Branch:** `docs/oracle-free-tier-limits`  
**Priority:** Low  
**Effort:** Low (1 hour)

### Problem

AGENTS.md mentions Oracle Free Tier limits, but doesn't document current usage or what happens when limits are hit. ARM instances get deleted after trial.

### Changes

- Create `docs/ORACLE_FREE_TIER.md`:

  ```markdown
  ## Current Usage
  - AMD Instances: 2/2 (FULL)
    - pam-amd1: 1 CPU / 1GB RAM (VPN gateway)
    - angela-amd2: 1 CPU / 1GB RAM (k3s worker)
  - ARM Instances: 2/4 OCPUs, 24/24 GB RAM (FULL)
    - stanley-arm1: 2 OCPU / 12GB RAM
    - phyllis-arm2: 2 OCPU / 12GB RAM
  - Remaining: 2 OCPU, 0 GB RAM (insufficient for new instance)
  
  ## ARM Instance Lifecycle
  - Created with 30-day trial
  - Auto-deleted after trial unless upgraded to paid
  - **Action Required:** Mark for recreation in Terraform before deletion
  
  ## What Happens When Limits Hit
  - New Terraform applies fail with capacity errors
  - Existing instances unaffected
  - Need to downsize or delete other instances to create new ones
  ```

- Add monitoring script: `scripts/check-oracle-capacity.sh`
- Link from README.md and AGENTS.md

### Benefits

- Clear visibility into resource usage
- Proactive ARM instance lifecycle management
- Avoid surprise capacity errors during Terraform applies

### Test

- Verify current usage matches documentation
- Run capacity check script

---

## PR #9: Standardize UFW Variable Names Across All Groups 🔧

**Branch:** `refactor/ufw-variable-consistency`  
**Priority:** Low  
**Effort:** Low (30 minutes)

### Problem

PR #277 added UFW variables to `pis.yml`, PR #278 added to `public_nodes.yml`. Both define `tailscale_network_cidr` but Pis also have `local_network_cidr` which public nodes don't need.

### Changes

- Move common variables to `ansible/group_vars/all.yml`:

  ```yaml
  # Network CIDRs (shared across all hosts)
  tailscale_network_cidr: "100.100.0.0/16"
  vpn_gateway_ip: "100.100.1.100"  # michael-pi
  ```

- Keep group-specific in respective files:

  ```yaml
  # pis.yml only
  local_network_cidr: "192.168.1.0/24"
  
  # public_nodes.yml only
  (no additional variables needed)
  ```

- Remove duplicate definitions

### Benefits

- Single source of truth for Tailscale network
- Easier to change Tailscale IP range if needed
- Cleaner variable hierarchy

### Test

- Run both playbooks → verify variables resolve correctly
- Check for no duplicates: `grep -r "tailscale_network_cidr" ansible/group_vars/`

---

## PR #10: Add Pre-commit Hook for Sensitive File Detection 🔒

**Branch:** `security/pre-commit-secrets-check`  
**Priority:** Medium  
**Effort:** Low (1 hour)

### Problem

Ansible Vault files (`ansible/confs/iptables.conf`) are encrypted, but someone could accidentally commit decrypted versions. No pre-commit check prevents this.

### Changes

- Update `.pre-commit-config.yaml`:

  ```yaml
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        exclude: ^(\.terraform/|\.git/)
  
  - repo: local
    hooks:
      - id: check-ansible-vault
        name: Check Ansible Vault files are encrypted
        entry: scripts/check-vault-encrypted.sh
        language: script
        files: ^ansible/confs/.*\.conf$
  ```

- Create `scripts/check-vault-encrypted.sh`:

  ```bash
  #!/bin/bash
  # Checks that files match "$ANSIBLE_VAULT;1.1;AES256" format
  # Exits 1 if unencrypted vault files detected
  ```

- Add to README.md "Contributing" section

### Benefits

- Prevent accidental secret leakage
- Automatic enforcement on every commit
- Complements existing TruffleHog secret scanning

### Test

- Try to commit unencrypted file → blocked by pre-commit
- Commit encrypted file → passes
- Run `pre-commit run --all-files` → passes on repo

---

## Implementation Order

**Phase 1: Documentation (Low Risk)**

- PR #1: Backup/restore documentation
- PR #8: Oracle free tier limits

**Phase 2: Code Quality (Low Risk)**

- PR #9: Standardize UFW variables
- PR #2: Standardize server naming

**Phase 3: CI/CD Improvements (Low Risk)**

- PR #6: Optimize caching
- PR #4: k3s dry-run validation
- PR #10: Pre-commit secrets check

**Phase 4: Monitoring (Medium Risk)**

- PR #3: Health checks dashboard
- PR #5: Tailscale monitoring

**Phase 5: Data Protection (High Value)**

- PR #7: Terraform state backup

---

## Quick Stats

| Category | Count |
|----------|-------|
| Documentation | 2 PRs |
| Security | 2 PRs |
| Monitoring | 2 PRs |
| CI/CD | 3 PRs |
| Refactoring | 2 PRs |
| **Total** | **10 PRs** |

**Estimated Total Effort:** 12-16 hours  
**Risk Level:** Low to Medium (no infrastructure changes)  
**Value:** High (improved reliability, security, and developer experience)

---

## Success Criteria

Each PR should:

- ✅ Pass all CI checks
- ✅ Be deployable independently
- ✅ Include documentation updates
- ✅ Have clear rollback procedure
- ✅ Take <1 day to review and merge

---

## Future Considerations (Not in this batch)

- Prometheus + Grafana monitoring
- Automated SSL certificate renewal alerts
- k3s upgrade automation
- Oracle ARM instance auto-recreation before trial expiry
- Centralized logging (ELK/Loki stack)
- Backup automation for Pi-hole/AdGuard configuration
