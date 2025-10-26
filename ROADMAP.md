# Homelab Development Roadmap

This document tracks all planned work, active projects, and their implementation details.
Each project is broken down into manageable PRs with clear scope, testing, and verification steps.

## PR Workflow

For each PR:

1. ✅ Ensure all tests are green

2. ✅ **Check for Codex review comments** (CRITICAL - don't skip!):

   ```bash
   # Step 1: Check if Codex reviewed
   gh pr view <PR_NUMBER> --json reviews --jq '.reviews[] | select(.author.login == "chatgpt-codex-connector") | {state: .state}'

   # Step 2: Get inline comments (P1/P2/P3 issues)
   gh api repos/slashr/homelab/pulls/<PR_NUMBER>/comments --jq '.[] | {id: .id, author: .user.login, path: .path, line: .line, body: .body}'
   ```

3. ✅ Address ALL Codex comments:
   - **Fix issues** OR **explain why no fix is needed**
   - **IMPORTANT:** Reply directly to Codex's inline comments (not as independent PR comment) to maintain context
   - Use: `gh api repos/slashr/homelab/pulls/<PR_NUMBER>/comments/<COMMENT_ID>/replies -X POST -f body="..."`
   - If subsequent fixes are pushed, request re-review: `@codex review`

4. ✅ Notify user for final approval

5. ✅ Merge only after user confirmation

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

## Roadmap Tasks

All planned PRs are listed below in logical execution order.

### Raspberry Pi Configuration

- [x] **PR #1: Pi Inventory + Variables**
  - Add `[pis]` group to `ansible/hosts.ini` (michael-pi, jim-pi, dwight-pi)
  - Create `ansible/group_vars/pis.yml` with common config

- [x] **PR #2: GitHub Actions Dry-Run Check**
  - Add `--check --diff` step to CI pipeline for Pi playbooks

- [x] **PR #3: Common Role - Packages**
  - Install base packages: vim, curl, htop, iotop, git, tmux

- [x] **PR #4: Common Role - System Config**
  - Timezone/locale, unattended-upgrades, MOTD

- [x] **PR #5: Network Role - WiFi Power Save Fix** 🔥
  - Disable WiFi power save to fix latency issues (jim-pi: 8s → <20ms)
  - **Priority: CRITICAL** - Fixes WiFi retries causing node health issues
  - Risk: Medium - Keep SSH session open during apply

- [x] **PR #6: Network Role - DNS Config**
  - Primary DNS: dwight-pi (100.100.1.102), fallbacks: Cloudflare, Google

- [x] **PR #7: Network Role - NTP Sync**
  - Configure NTP for time synchronization

- [ ] **PR #8: k3s Prerequisites - Runtime Config**
- Sysctls: `net.ipv4.ip_forward=1`, bridge-nf-call-iptables
- Kernel modules: br_netfilter, overlay

- [ ] **PR #9: k3s Prerequisites - Boot Config**
- Boot cmdline: `cgroup_memory=1 cgroup_enable=memory`
  - Risk: Medium - Requires reboot

### Security Hardening - Raspberry Pis

- [ ] **PR #10: Pi Security - SSH Hardening**
  - SSH: key-only auth, no root login, no password auth
  - Risk: Medium - Keep 2 SSH sessions open during apply

- [ ] **PR #11: Pi Security - UFW Firewall**
  - Default deny incoming, allow SSH (22), k3s (6443, 10250), Tailscale (41641)

### Security Hardening - Public Cloud Nodes

- [ ] **PR #12: Public Nodes Inventory + Variables**
  - Add `[public_nodes]` group to `ansible/hosts.ini` (angela-amd2, stanley-arm1, phyllis-arm2, toby-gcp1)
  - Create `ansible/group_vars/public_nodes.yml` with fail2ban and UFW config

- [ ] **PR #13: fail2ban Role - SSH Protection** 🔥
  - Deploy fail2ban with SSH jail (3 strikes → 24h ban)
  - **Priority: CRITICAL** - Mitigates 25,891 daily SSH brute force attacks
  - Rollout: toby-gcp1 → phyllis → stanley → angela

- [ ] **PR #14: Public Nodes - UFW Firewall**
  - UFW with rate-limited SSH (6 conn/30s)
  - Allow Tailscale (41641/udp) and k3s traffic from Tailscale network only
  - Risk: Medium - Keep 2 SSH sessions open, test on toby-gcp1 first

- [ ] **PR #15: Security Monitoring & Reporting**
  - Daily fail2ban reports: banned IPs, attack volumes, top attackers
  - Cron job at 9 AM daily

### Ansible Performance Optimization

- [ ] **PR #16: Optimize vpn.yml Execution**
  - Add `strategy: free` for parallel host execution
  - Add `gather_facts: false` where not needed

- [ ] **PR #17: Add ansible.cfg**
  - Enable SSH pipelining and ControlPersist
   - Set forks = 10

- [x] **PR #18: Skip VPN Playbook on PRs**
  - Only run actual playbook on push to main
   - Keep dry-run check on PRs

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
