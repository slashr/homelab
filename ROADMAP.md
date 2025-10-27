# Homelab Development Roadmap

This document tracks all planned work, active projects, and their implementation details.
Each project is broken down into manageable PRs with clear scope, testing, and verification steps.

📝 **See [COMPLETED.md](COMPLETED.md) for historical record of finished PRs.**

---

## PR Workflow

For each PR:

1. ✅ Ensure all tests are green

2. ✅ **Check for Codex review comments** (CRITICAL - don't skip!):

   **⚠️ IMPORTANT: Codex uses a two-step comment structure:**
   - First posts a **main comment**: "Codex Review"
   - Then posts the **actual review issues as replies** to that main comment (P1/P2/P3 issues)
   - **You must check the REPLIES** - the main comment alone does NOT contain the review details!

   **How to find Codex review comments:**

   ```bash
   # Step 1: Request Codex review (if not already reviewed)
   gh pr comment <PR_NUMBER> --body "@codex review"

   # Step 2: Wait for Codex to complete (IMPORTANT!)
   # - Main "Codex Review" comment appears within ~10-30 seconds
   # - Actual review replies may take 2-3 minutes MORE to appear
   # - ALWAYS wait at least 2-3 minutes after requesting review before checking
   sleep 180

   # Step 3: Find the main Codex comment ID
   gh api repos/slashr/homelab/issues/<PR_NUMBER>/comments --jq '.[] | select(.user.login == "chatgpt-codex-connector[bot]" and (.body | contains("Codex Review"))) | {id: .id, created_at: .created_at}'

   # Step 4: Check for review replies under the main comment
   # (Codex posts P1/P2/P3 issues as replies to the main comment)
   gh api repos/slashr/homelab/issues/comments/<MAIN_COMMENT_ID> --jq '.body'
   
   # Or view all replies in the PR thread on GitHub web UI
   ```

   **What to look for:**
   - 🔴 **P1 (orange badge)**: Critical bugs that MUST be fixed
   - 🟡 **P2 (yellow badge)**: Important issues that should be fixed
   - 🔵 **P3 (blue badge)**: Nice-to-have improvements
   - ✅ **"Didn't find any major issues"**: Only appears when there are NO review issues

3. ✅ Address ALL Codex review issues:
   - **IMPORTANT:** Reply directly to Codex's comment thread (as a reply), NOT as a separate main PR comment
   - Each reply should either:
     - **Accept and fix**: "Fixed in commit abc123 by [describe change]"
     - **Explain why no fix needed**: "Not fixing because [specific reason]"
   - Use GitHub web UI to reply to the comment thread, OR use CLI:

     ```bash
     gh api repos/slashr/homelab/issues/comments/<MAIN_COMMENT_ID>/replies -X POST -f body="..."
     ```

   **After pushing fixes:**
   - Request re-review: `gh pr comment <PR_NUMBER> --body "@codex review"`
   - Wait 2-3 minutes for Codex to complete new review
   - Check for new replies to confirm issues are resolved

4. ✅ Notify user for final approval

5. ✅ Merge only after user confirmation

---

## Branch Management

**ALWAYS follow this sequence when starting a new PR:**

1. **Start from main:**

   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create new feature branch:**

   ```bash
   git checkout -b <feature-branch-name>
   ```

3. **Verify you're on the right branch:**

   ```bash
   git branch --show-current  # Should show feature-branch-name, NOT main
   ```

4. **When checking PR status, ensure you're monitoring the FEATURE BRANCH:**
   - PR checks run against the feature branch
   - Don't switch to main while debugging PR issues
   - Use `git branch --show-current` if confused

5. **If you accidentally start from wrong branch:**
   - Don't push! Rebase onto main first
   - Or delete branch and start over

**Common Mistakes to Avoid:**

- ❌ Creating branch from another unmerged feature branch
- ❌ Switching to main while debugging PR checks
- ❌ Forgetting to pull latest main before branching
- ❌ Working on main branch directly

---

## Deployment Strategy

**Staged Rollout (Preferred for All Changes):**

All Ansible playbooks targeting Raspberry Pis use a staged rollout pattern:

1. **dwight-pi** - catches issues early
2. **jim-pi** - regular worker
3. **michael-pi** - most critical, updated last

**CI/CD Behavior:**

- **PR dry-run**: Checks all 3 Pis simultaneously
- **Main branch apply**: Runs dwight → jim → michael

**Why:**

- Safer: Issues caught on dwight-pi before affecting workers or master
- Clear: michael-pi updated last as it's most critical
- Fast: Parallel dry-run for quick validation

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
