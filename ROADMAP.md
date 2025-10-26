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

### Security Hardening - SSH Brute Force Protection

**Status:** Planned  
**Goal:** Eliminate SSH brute force attacks and reduce resource consumption on public nodes  
**Priority:** 🔥 **CRITICAL**

**Problem:**

Security audit revealed severe attack volume:
- **25,891 SSH brute force attempts** in 24 hours across 4 public nodes
- Angela: 9,228 attacks/day (6.4 per minute) - contributing to 800% CPU overload
- Stanley: 7,907 attacks/day
- Phyllis: 5,825 attacks/day  
- Toby-GCP: 2,931 attacks/day
- **Zero protection**: No fail2ban, inactive/missing firewalls
- 198 root login attempts in 7 days
- Top attacker IPs: 223.123.92.149 (1,802 attempts), 196.251.80.29 (1,232+)

**Solution:**

Deploy fail2ban and UFW firewall across all public nodes to block attackers and free up resources.

**Scope:**

- fail2ban with aggressive SSH protection (3 strikes → 24h ban)
- UFW firewall with rate-limited SSH access
- Monitoring and alerting for attack volumes
- Oracle Cloud Security List hardening

**Architecture:**

```text
ansible/
├── playbooks/
│   └── security.yml           # Main security playbook
├── roles/
│   ├── fail2ban/
│   │   ├── tasks/main.yml     # Install and configure
│   │   ├── templates/
│   │   │   └── jail.local.j2  # Custom jail config
│   │   └── handlers/main.yml  # Service restart
│   └── firewall/
│       ├── tasks/main.yml     # UFW configuration
│       └── templates/
│           └── ufw-rules.j2   # Firewall rules
└── group_vars/
    └── public_nodes.yml       # Oracle + GCP nodes
```

**Key Configuration:**

```yaml
# group_vars/public_nodes.yml
fail2ban_enabled: true
fail2ban_bantime: 86400  # 24 hours
fail2ban_maxretry: 3
fail2ban_findtime: 600   # 10 minutes

ufw_ssh_rate_limit: true
ufw_default_incoming: deny
ufw_allowed_services:
  - { port: 22, proto: tcp, rule: limit }        # SSH rate-limited
  - { port: 6443, proto: tcp, from: "100.100.0.0/16" }  # k3s API (Tailscale only)
  - { port: 10250, proto: tcp, from: "100.100.0.0/16" } # kubelet (Tailscale only)
  - { port: 41641, proto: udp }                  # Tailscale
```

## Implementation (5 PRs)

### PR #1: Update Inventory for Public Nodes ✅

**This file** - Add security hardening roadmap section

- **Size:** ~150 lines
- **Risk:** None (documentation only)
- **Testing:** Review only

**Changes:**
- Add security hardening section to ROADMAP.md
- Document attack patterns and mitigation strategy
- Break down into manageable PRs

**Verify:**
- [ ] PR follows existing ROADMAP.md format
- [ ] All PRs scoped and testable

### PR #2: Create Public Nodes Group + Variables

Add `[public_nodes]` inventory group and security configuration variables.

- **Size:** ~30 lines
- **Risk:** None (no execution)
- **Targets:** angela-amd2, stanley-arm1, phyllis-arm2, toby-gcp1

**Changes:**

```ini
# ansible/hosts.ini
[public_nodes]
angela-amd2
stanley-arm1
phyllis-arm2
toby-gcp1
```

```yaml
# ansible/group_vars/public_nodes.yml
---
# fail2ban configuration
fail2ban_enabled: true
fail2ban_bantime: 86400    # 24 hours
fail2ban_maxretry: 3       # 3 failed attempts
fail2ban_findtime: 600     # within 10 minutes
fail2ban_destemail: ""     # Optional: alert email

# UFW firewall
ufw_enabled: true
ufw_default_incoming: deny
ufw_default_outgoing: allow
ufw_ssh_rate_limit: true
```

**Testing:**

```bash
# Verify inventory
ansible-inventory -i ansible/hosts.ini --list --yaml | grep -A 10 public_nodes

# Verify variables
ansible public_nodes -i ansible/hosts.ini -m debug -a "var=fail2ban_enabled"
ansible public_nodes -i ansible/hosts.ini -m ping
```

**Verify:**
- [ ] 4 nodes in public_nodes group
- [ ] Variables accessible to all nodes
- [ ] No syntax errors

### PR #3: fail2ban Role - Installation & Basic Config

Deploy fail2ban with SSH jail configuration.

- **Size:** ~120 lines
- **Risk:** Low (only monitors, doesn't block yet)
- **Rollout:** toby-gcp1 → phyllis → stanley → angela

**Changes:**

Create `ansible/roles/fail2ban/` with:

1. **tasks/main.yml** - Install fail2ban, create config, enable service
2. **templates/jail.local.j2** - SSH jail with configured ban times
3. **handlers/main.yml** - Restart fail2ban on config changes

**Testing:**

```bash
# Dry run on toby-gcp1 first (lowest attack volume)
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml \
  --limit toby-gcp1 --tags fail2ban --check --diff

# Apply to toby-gcp1
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml \
  --limit toby-gcp1 --tags fail2ban

# Verify installation
ssh dev@toby-gcp1 "sudo fail2ban-client status"
ssh dev@toby-gcp1 "sudo fail2ban-client status sshd"

# Test ban functionality (from external IP)
# Try 4 failed SSH attempts, should get banned on 4th

# Verify ban
ssh dev@toby-gcp1 "sudo fail2ban-client status sshd | grep 'Banned IP'"

# Unban test IP
ssh dev@toby-gcp1 "sudo fail2ban-client set sshd unbanip <test-ip>"
```

**Verify:**
- [ ] fail2ban service active and enabled
- [ ] SSH jail enabled and monitoring
- [ ] Ban works after 3 failed attempts
- [ ] Can SSH successfully with valid key
- [ ] Idempotent (second run = 0 changes)

**Rollback:**

```bash
ansible public_nodes -i ansible/hosts.ini -b -m systemd \
  -a "name=fail2ban state=stopped enabled=no"
ansible public_nodes -i ansible/hosts.ini -b -m apt \
  -a "name=fail2ban state=absent purge=yes"
```

### PR #4: UFW Firewall Role - Basic Rules

Configure UFW with rate-limited SSH and Tailscale access.

- **Size:** ~100 lines
- **Risk:** Medium (firewall changes, SSH lockout possible)
- **Safety:** Allow Tailscale IPs before enabling, test on toby-gcp1 first

**Changes:**

Create `ansible/roles/firewall/` with UFW configuration:

1. **tasks/main.yml** - Configure UFW rules, enable firewall
2. **templates/ufw-rules.j2** - Rule definitions (optional)

**Rules:**
- Allow SSH (port 22) with rate limiting (6 conn/30s)
- Allow Tailscale (port 41641/udp)
- Allow k3s traffic from Tailscale network (100.100.0.0/16)
- Default deny incoming, allow outgoing

**Testing:**

```bash
# CRITICAL: Keep 2 SSH sessions open during testing!

# Session 1: Dry run
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml \
  --limit toby-gcp1 --tags firewall --check --diff

# Session 1: Apply
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml \
  --limit toby-gcp1 --tags firewall

# Session 2: Test new connection immediately
ssh dev@toby-gcp1 "echo 'SSH still works'"

# Verify rules
ssh dev@toby-gcp1 "sudo ufw status verbose"

# Test k3s connectivity
kubectl get nodes  # Should work
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=5  # Should work

# Test rate limiting (from external IP)
for i in {1..7}; do ssh dev@toby-gcp1 "echo test" & done
# 7th connection should be denied
```

**Verify:**
- [ ] UFW active
- [ ] SSH works (both direct and via Tailscale)
- [ ] k3s API accessible from master node
- [ ] Rate limiting active (7th rapid connection fails)
- [ ] No services disrupted
- [ ] Idempotent

**Rollback:**

```bash
ssh user@node "sudo ufw disable"
```

**Emergency Access (if locked out):**

Use Oracle Cloud Console → Instance → Console Connection, then:
```bash
sudo ufw disable
sudo systemctl stop ufw
```

### PR #5: Monitoring & Reporting

Add fail2ban monitoring script and daily attack reports.

- **Size:** ~80 lines  
- **Risk:** None (monitoring only)

**Changes:**

1. **monitoring script** - `/usr/local/bin/fail2ban-report.sh`
   - Daily banned IP count
   - Top attacking IPs
   - Ban/unban events
   
2. **cron job** - Daily report at 9 AM
   - Run on each public node
   - Can optionally email results

**Script Features:**

```bash
#!/bin/bash
# /usr/local/bin/fail2ban-report.sh

echo "=== fail2ban Daily Report: $(hostname) ==="
echo "Date: $(date)"
echo ""

echo "[Currently Banned IPs]"
sudo fail2ban-client status sshd | grep "Banned IP list" | cut -d: -f2

echo -e "\n[Ban Statistics - Last 24h]"
sudo journalctl -u fail2ban --since "24 hours ago" | grep "Ban " | wc -l

echo -e "\n[Top 10 Banned IPs - Last 7 days]"
sudo journalctl -u fail2ban --since "7 days ago" | \
  grep "Ban " | awk '{print $NF}' | sort | uniq -c | sort -rn | head -10

echo -e "\n[Recent Bans - Last 20]"
sudo journalctl -u fail2ban --since "24 hours ago" | grep "Ban " | tail -20
```

**Testing:**

```bash
# Deploy script
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml \
  --tags monitoring

# Run manually
ansible public_nodes -i ansible/hosts.ini -b -a "/usr/local/bin/fail2ban-report.sh"

# Verify cron job
ansible public_nodes -i ansible/hosts.ini -b -a "crontab -l | grep fail2ban"
```

**Verify:**
- [ ] Script executable on all nodes
- [ ] Script runs without errors
- [ ] Cron job configured
- [ ] Report format readable

## Execution Pattern

```bash
# Full security hardening (in order)
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml

# Single role
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml --tags fail2ban
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml --tags firewall

# Single node (testing)
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml --limit toby-gcp1

# Staged rollout (safest)
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml --limit toby-gcp1
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml --limit phyllis-arm2
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml --limit stanley-arm1
ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml --limit angela-amd2

# Check banned IPs
ansible public_nodes -i ansible/hosts.ini -b -a "fail2ban-client status sshd"

# Unban IP (emergency)
ansible public_nodes -i ansible/hosts.ini -b -a "fail2ban-client set sshd unbanip <IP>"
```

## Success Criteria

**Technical:**

- fail2ban: Active on all 4 public nodes
- UFW: Active with rate-limited SSH
- Attack volume: Reduced by 90%+ (from 25,891/day to <2,000/day)
- Banned IPs: 50-100 per day steady state
- CPU usage (angela): Reduced by 10-15% 
- SSH access: No legitimate lockouts
- k3s: All pods healthy, API accessible
- Idempotent: 2 runs = 0 changes

**Operational:**

- No false positives (legitimate IPs banned)
- Daily monitoring reports working
- Emergency unban process documented
- Zero downtime during deployment

## Safety Measures

1. **Testing Order:** toby-gcp1 → phyllis → stanley → angela (lowest to highest attack volume)
2. **SSH Sessions:** Keep 2 sessions open during firewall changes
3. **Rollback Plan:** Document commands to disable fail2ban/UFW
4. **Emergency Access:** Oracle Cloud Console for firewall lockout
5. **Staging:** Dry-run with `--check --diff` before apply
6. **Monitoring:** Check for false positives daily for first week

## Expected Impact

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Daily Attacks** | 25,891 | <2,000 | **92%** |
| **CPU Load (angela)** | 7.96 | 5-6 | **25-30%** |
| **Banned IPs/day** | 0 | 50-100 | **Active defense** |
| **Resource Waste** | High | Minimal | **Significant** |
| **Attack Success** | 0% | 0% | **Maintained** |

## Timeline

- **Execution:** 5 PRs, sequential, progressively deploy
- **Estimated Time:** 2-3 days total (including monitoring period)
- **Priority:** 🔥 CRITICAL - Start immediately
- **Next:** PR #1 - Update ROADMAP.md (this file)

## Future Enhancements (Optional)

After core deployment stabilizes:

1. **Crowdsec Integration** - Shared threat intelligence, better than fail2ban alone
2. **IP Whitelisting** - Restrict SSH to known IPs if static IP available  
3. **SSH Port Change** - Move from 22 to 2222 (eliminates 99% of scanner traffic)
4. **Oracle Security Lists** - Cloud-level firewall rules
5. **2FA for SSH** - Google Authenticator PAM module
6. **Grafana Dashboard** - Visualize attack patterns and ban rates
7. **Tailscale-Only SSH** - Block port 22 publicly, use Tailscale for all access

---

*Add new projects below. Each should include Project Name, Goal, Scope, PRs, Timeline.*
