# Homelab Development Roadmap

This document tracks all planned work, active projects, and their implementation details.
Each project is broken down into manageable PRs with clear scope, testing, and verification steps.

## PR Workflow

For each PR:

1. ✅ Ensure all tests are green
2. ✅ Get reviewed by `@codex`:
   - Codex will usually start the review automatically and leave comments if any
   - Address comments by either fixing them or replying why a fix isn't needed
   - **IMPORTANT:** Reply directly to Codex's inline comments (not as independent PR comment) to maintain context
   - If subsequent fixes are pushed after initial PR creation, request re-review using `@codex review`
3. ✅ Notify user for final approval
4. ✅ Merge only after user confirmation

## Branch Management (Critical!)

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

1. **dwight-pi first** (canary) - catches issues early
2. **jim-pi second** - regular worker
3. **michael-pi last** (k3s master) - most critical

**CI/CD Behavior:**

- **PR dry-run**: Checks all 3 Pis simultaneously (shows what would change)
- **Main branch apply**: Runs dwight → jim → michael (staged deployment)

**Why:**

- Safer: Issues caught on dwight-pi before affecting workers or k3s master
- Clear: k3s master (michael-pi) updated last as it's most critical
- Fast: Parallel dry-run for quick validation

---

## Active Project: Raspberry Pi GitOps Migration

**Status:** In Progress (PR #256)  
**Goal:** Bring michael-pi, jim-pi, and dwight-pi under Ansible GitOps management  
**Scope:** Essential config only (OS, SSH, network, k3s prerequisites)

### Problem

- jim-pi going unhealthy (8s WiFi latency → monitoring failures)
- Configuration drift across all Pis (jim: 343 retries, dwight: 4325 retries)
- No standardized config management

## Solution

Ansible roles for: base system, security, network (WiFi fix), k3s prereqs

## Architecture

```text
ansible/
├── hosts.ini                  # Add [pis] group
├── group_vars/
│   └── pis.yml                # Common Pi config
├── roles/
│   ├── common/                # Packages, timezone, updates
│   ├── security/              # SSH hardening, UFW
│   ├── network/               # WiFi power save fix, DNS, NTP
│   └── k3s_prereqs/          # Cgroups, sysctls, modules
└── playbooks/
    ├── pis.yml               # Main Pi playbook
    ├── verify.yml            # Validation
    ├── vpn.yml              # Existing
    └── k3s.yml              # Existing
```

## Key Configuration

```yaml
# group_vars/pis.yml
wifi_power_save_disabled: true
dns_servers:
  - 100.100.1.102  # dwight-pi (AdGuard) via Tailscale
  - 1.1.1.1        # Cloudflare fallback
  - 8.8.8.8        # Google fallback
ssh_permit_root_login: false
ssh_password_authentication: false
base_packages: [vim, curl, htop, iotop, git, tmux]
```

## Implementation (12 PRs)

### PR #1: Planning Document ✅

- **This file**
- Size: ~50 lines
- Risk: None

### PR #2: Inventory + Variables

- Add `[pis]` group to `hosts.ini` with michael-pi, jim-pi, dwight-pi
- Create `group_vars/pis.yml` with common config
- Size: ~20 lines (super simple!)
- Risk: Low (no execution)

**Changes:**

```ini
# hosts.ini - just add this at the end
[pis]
michael-pi
jim-pi
dwight-pi
```

**Testing:**

```bash
ansible-inventory -i hosts.ini --list --yaml
ansible pis -i hosts.ini -m debug -a "var=wifi_power_save_disabled"
ansible pis -i hosts.ini -m ping
```

### PR #3: GitHub Actions Dry-Run Check

- Add Ansible check mode to CI pipeline
- Runs on PRs to show what would change before merge
- Size: ~30 lines (workflow only)
- Risk: None (CI-only change)

**Changes:**

Add dry-run check step to `.github/workflows/actions.yml` in `tailscale-setup` job:

- Runs `ansible-playbook --check --diff` on PRs only
- Tests on jim-pi (limit)
- Shows diff preview in PR summary
- Skips gracefully if playbook doesn't exist

**Testing:**

```bash
# Trigger by creating a PR - check the step summary in Actions
```

**Verify:**

- [ ] Step shows up in PR checks
- [ ] Skips gracefully when no playbook exists
- [ ] Will show diff once playbooks are added

### PR #4: Common Role - Packages

- Install base packages only: vim, curl, htop, iotop, git, tmux
- Size: ~50 lines
- Risk: Very Low

**Changes:**

1. Create `roles/common/tasks/main.yml` with package installation
2. Create `playbooks/pis.yml` to apply common role

**Testing:**

```bash
# Local dry-run
ansible-playbook -i hosts.ini playbooks/pis.yml \
  --check --diff --limit jim-pi --tags packages

# Actual apply
ansible-playbook -i hosts.ini playbooks/pis.yml --limit jim-pi --tags packages
```

**Verify:**

- [ ] `which vim && which htop && which git` all succeed
- [ ] GitHub Actions shows dry-run diff in PR summary

### PR #5: Common Role - System Config

- Timezone/locale (Europe/London, en_GB.UTF-8)
- Unattended-upgrades for security patches
- MOTD with node info
- Size: ~80 lines
- Risk: Low

**Testing:**
```bash
ansible-playbook -i hosts.ini playbooks/pis.yml --limit jim-pi --tags system
ssh jim-pi "timedatectl"
ssh jim-pi "systemctl status unattended-upgrades"
```

**Verify:**

- [ ] Timezone correct
- [ ] Unattended-upgrades running
- [ ] MOTD shows node info

### PR #6: Network Role - WiFi Fix 🔥 **CRITICAL**

- **Disable WiFi power save ONLY** (NetworkManager + dhcpcd detection)
- Size: ~60 lines
- Risk: Medium (network changes)

**Safety:**

- Apply to jim-pi first (already manually fixed)
- Keep SSH session open during apply

**Testing:**

```bash
ansible-playbook -i hosts.ini playbooks/pis.yml --limit jim-pi --tags wifi

# Verify
ssh jim-pi "dmesg | grep 'power save'"  # Should say "disabled"
ssh jim-pi "ping -c 10 100.100.1.100 | tail -2"  # Should be <10ms avg
ssh jim-pi "cat /proc/net/wireless"  # Retry count stops increasing

# Then michael-pi, then dwight-pi
ansible-playbook -i hosts.ini playbooks/pis.yml --limit michael-pi --tags wifi
ansible-playbook -i hosts.ini playbooks/pis.yml --limit dwight-pi --tags wifi
```

**Verify:**

- [ ] Power save disabled on all nodes
- [ ] Latency <20ms to master
- [ ] WiFi retry count stops increasing

**Rollback:**

```bash
ssh pi "sudo sed -i 's/wifi.powersave = 1/wifi.powersave = 2/' /etc/NetworkManager/conf.d/wifi-powersave.conf"
ssh pi "sudo systemctl reload NetworkManager"
```

### PR #7: Network Role - DNS Config

- Configure DNS: dwight-pi (100.100.1.102) primary, fallbacks
- Size: ~40 lines
- Risk: Low

**Testing:**
```bash
ansible-playbook -i hosts.ini playbooks/pis.yml --limit jim-pi --tags dns

# Verify
ssh jim-pi "cat /etc/resolv.conf"  # Check nameservers
ssh jim-pi "nslookup google.com"  # Should work
ssh jim-pi "nslookup ads.doubleclick.net"  # Should be blocked
```

**Verify:**

- [ ] DNS resolves via dwight-pi
- [ ] Ad blocking works
- [ ] Fallback DNS configured

### PR #8: Network Role - NTP Sync

- Configure NTP for time sync
- Size: ~30 lines
- Risk: Very Low

**Testing:**
```bash
ansible-playbook -i hosts.ini playbooks/pis.yml --limit jim-pi --tags ntp
ssh jim-pi "timedatectl status"
```

**Verify:**

- [ ] NTP synchronized: yes

### PR #9: Security Role - SSH Hardening

- SSH: key-only, no root, no password auth ONLY
- Size: ~80 lines
- Risk: Medium (SSH lockout risk)

**Safety:**

- **Keep 2 SSH sessions open** before applying
- Config validation: `sshd -t -f %s`
- Backup created automatically

**Testing:**

```bash
# jim-pi first (keep 2nd session open!)
ansible-playbook -i hosts.ini playbooks/pis.yml --limit jim-pi --tags ssh

# In 2nd session, verify new connection works
ssh jim-pi "echo 'SSH works'"

# Test password auth blocked
ssh -o PreferredAuthentications=password pi@jim-pi  # Should fail
```

**Verify:**

- [ ] Password auth blocked
- [ ] Key auth works
- [ ] No SSH lockout

**Rollback:**

```bash
ssh pi "sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config"
ssh pi "sudo systemctl restart sshd"
```

### PR #10: Security Role - Firewall (UFW)

- UFW: default deny, allow SSH (22), k3s (6443, 10250), Tailscale (41641)
- Size: ~70 lines
- Risk: Low

**Testing:**

```bash
ansible-playbook -i hosts.ini playbooks/pis.yml --limit jim-pi --tags firewall
ssh jim-pi "sudo ufw status verbose"
```

**Verify:**

- [ ] UFW active
- [ ] Required ports allowed
- [ ] Can still SSH in

### PR #11: k3s Prerequisites - Runtime Config

- Sysctls: `net.ipv4.ip_forward=1`, bridge-nf-call-iptables
- Kernel modules: br_netfilter, overlay
- Size: ~60 lines
- Risk: Low (no reboot needed)

**Testing:**

```bash
ansible-playbook -i hosts.ini playbooks/pis.yml --limit jim-pi --tags k3s_runtime

# Verify
ssh jim-pi "sysctl net.ipv4.ip_forward"  # Should be 1
ssh jim-pi "lsmod | grep br_netfilter"   # Should be loaded
```

**Verify:**

- [ ] Sysctls applied
- [ ] Modules loaded
- [ ] Persistent across reboots

### PR #12: k3s Prerequisites - Boot Config

- Boot cmdline: `cgroup_memory=1 cgroup_enable=memory`
- Size: ~50 lines
- Risk: Medium (requires reboot)

**Safety:**

- Backup `/boot/firmware/cmdline.txt` created automatically
- Apply to jim-pi first (worker, less critical)
- Verify k3s still works after reboot

**Testing:**

```bash
# jim-pi first
ansible-playbook -i hosts.ini playbooks/pis.yml --limit jim-pi --tags k3s_boot

# Reboot
ssh jim-pi "sudo reboot"

# Wait 2 min, verify
ssh jim-pi "cat /proc/cmdline | grep cgroup"
kubectl get nodes  # jim-pi should be Ready

# Then michael-pi (coordinate downtime), then dwight-pi
```

**Verify:**

- [ ] Boot cmdline has cgroup params
- [ ] k3s nodes Ready after reboot

**Rollback:**

```bash
ssh pi "sudo cp /boot/firmware/cmdline.txt.backup /boot/firmware/cmdline.txt"
ssh pi "sudo reboot"
```

## Execution Pattern

```bash
# 1. Syntax check
ansible-playbook playbook.yml --syntax-check

# 2. Dry run
ansible-playbook -i hosts.ini playbooks/pis.yml --check --diff

# 3. Apply to single node
ansible-playbook -i hosts.ini playbooks/pis.yml --limit jim-pi

# 4. Verify idempotency (0 changes)
ansible-playbook -i hosts.ini playbooks/pis.yml --limit jim-pi

# 5. Validation
ansible-playbook -i hosts.ini playbooks/verify.yml --limit jim-pi

# 6. Roll out to all Pis
ansible-playbook -i hosts.ini playbooks/pis.yml
```

## Success Criteria

**Technical:**

- WiFi latency: <20ms avg (from 8000ms)
- WiFi retries: <100 accumulated (from 343-4325)
- All nodes: Ready status
- SSH: Key-only enforced
- UFW: Active on all nodes
- Idempotent: 2 runs = 0 changes

**Operational:**

- Documentation complete
- `verify.yml` passes
- New Pi can join via playbook only

## Key Decisions

1. **Simple `[pis]` group**: Just list all 3 Pis, no complex structure needed
2. **Runtime detection**: Roles auto-detect NetworkManager vs dhcpcd
3. **Tailscale IPs for DNS**: Works when Pis are remote from LAN
4. **dwight-pi as DNS**: Primary for ad blocking, fallbacks for reliability
5. **No fail2ban**: UFW rate limiting sufficient for homelab + Tailscale
6. **Dynamic over static**: Roles detect state vs relying on variables

## Quick Reference

```bash
# Full setup (in order)
ansible-playbook -i hosts.ini playbooks/vpn.yml
ansible-playbook -i hosts.ini playbooks/pis.yml
ansible-playbook -i hosts.ini playbooks/k3s.yml

# Pi updates only
ansible-playbook -i hosts.ini playbooks/pis.yml

# Single role/tag
ansible-playbook -i hosts.ini playbooks/pis.yml --tags wifi
ansible-playbook -i hosts.ini playbooks/pis.yml --tags dns

# Single node
ansible-playbook -i hosts.ini playbooks/pis.yml --limit jim-pi

# Verify all Pis
ansible-playbook -i hosts.ini playbooks/verify.yml

# Drift detection
ansible-playbook -i hosts.ini playbooks/pis.yml --check --diff
```

## Timeline

- **Execution:** 12 PRs, sequential, each very small
- **Status:** Planning complete, PR #1 merged, PR #2 in review
- **Next:** PR #3 - GitHub Actions dry-run check
- **Strategy:** Smaller PRs = safer rollout, easier to verify, faster to rollback

## Notes

- jim-pi currently has **temporary manual fix** (WiFi power save disabled)
- Fix won't survive reboot until PR #6 merged
- All Pis have same WiFi issue, just different severity
- dwight-pi: 4325 retries (worst), jim-pi: 343 retries

---

## Future Projects / Backlog

### Ansible Performance Optimization

**Goal:** Reduce CI/CD pipeline execution time from 3-5 minutes to 1-2 minutes

**Problem:** Ansible Tailscale job is slow due to sequential execution and redundant runs on PRs

**Scope:**

- Add `strategy: free` to vpn.yml for parallel host execution
- Add `gather_facts: false` where facts aren't needed
- Configure SSH pipelining and ControlPersist in ansible.cfg
- Skip actual playbook execution on PRs (dry-run only)

**PRs:**

1. **PR: Optimize vpn.yml execution strategy**
   - Add `strategy: free` to Play 2 (Tailscale installation)
   - Add `gather_facts: false` after verifying facts aren't used
   - Test: Measure before/after execution time

2. **PR: Add ansible.cfg with SSH optimizations**
   - Enable pipelining
   - Configure ControlPersist
   - Set forks = 10

3. **PR: Skip vpn-playbook execution on PRs**
   - Add `if: github.event_name == 'push'` to actual playbook run
   - Keep dry-run check on PRs
   - Only apply changes on push to main

**Expected Impact:**

- Main branch: 3-5 min → 1-2 min (60-70% faster)
- PR checks: 3-5 min → ~30s (dry-run only)
- No functionality changes, pure optimization

**Timeline:** 3 small PRs, <1 day total

---

*Add new projects below. Each should include Project Name, Goal, Scope, PRs, Timeline.*
