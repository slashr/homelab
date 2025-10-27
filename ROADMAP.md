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

- [x] **PR #1: Add Raspberry Pi inventory group and configuration variables**
  - Added `[pis]` group to `ansible/hosts.ini` with michael-pi, jim-pi, dwight-pi
  - Created `ansible/group_vars/pis.yml` with shared configuration
  - Configured Tailscale IPs (100.100.1.x), ansible_user, python interpreter paths
  - Base packages list, DNS servers, WiFi settings all centralized

- [x] **PR #2: Add Ansible dry-run checks to GitHub Actions**
  - Added dry-run validation in `.github/workflows/actions.yml` (line 270)
  - Runs `ansible-playbook --check` on PRs before merge
  - Only runs if Pi-related files changed (reduces CI time)
  - Shows diff preview in PR summary for review

- [x] **PR #3: Install essential system packages on Raspberry Pis**
  - Created `ansible/roles/common/tasks/main.yml`
  - Installs: vim, curl, htop, iotop, git, tmux via apt
  - Uses `base_packages` variable from group_vars for flexibility
  - Tagged with `packages` for selective execution

- [x] **PR #4: Configure timezone, locale, and automatic security updates**
  - Set timezone to Europe/Berlin, locale to en_GB.UTF-8
  - Installed and enabled unattended-upgrades for automatic security patches
  - Created custom MOTD showing hostname, IP, OS version, kernel
  - All in `ansible/roles/common/tasks/main.yml`, tagged with `system`

- [x] **PR #5: Fix WiFi power save causing network latency and retries** 🔥
  - **Priority: CRITICAL** - Fixed jim-pi latency (8000ms → <20ms), reduced retries (4325 → <100)
  - Implemented in `ansible/roles/network/tasks/main.yml`
  - Detects NetworkManager or dhcpcd and configures accordingly
  - NetworkManager: Creates `/etc/NetworkManager/conf.d/wifi-powersave.conf` with `wifi.powersave = 2`
  - dhcpcd: Creates `/etc/dhcpcd.enter-hook` to run `iwconfig wlan0 power off`
  - Immediately disables at runtime: `iwconfig wlan0 power off`
  - Tagged with `wifi` for targeted deployment

- [x] **PR #6: Configure DNS with AdGuard on dwight-pi**
  - Primary DNS: 100.100.1.102 (dwight-pi AdGuard via Tailscale)
  - Fallbacks: 1.1.1.1 (Cloudflare), 8.8.8.8 (Google)
  - Template: `ansible/roles/network/templates/resolv.conf.j2` → `/etc/resolv.conf`
  - Prevents overwrite by NetworkManager and dhcpcd
  - Provides ad-blocking and works when Pis are remote from LAN

- [x] **PR #7: Configure NTP time synchronization**
  - Enables and starts `systemd-timesyncd` service
  - Configures NTP servers: 0-3.pool.ntp.org, fallback to Cloudflare/Google time servers
  - Config file: `/etc/systemd/timesyncd.conf`
  - Ensures accurate timestamps for logs and scheduled tasks
  - Tagged with `ntp` in `ansible/roles/network/tasks/main.yml`

- [ ] **PR #8: Add k3s runtime prerequisites role for Raspberry Pis**
  - Create `ansible/roles/k3s_prereqs/tasks/main.yml` with runtime configuration
  - Set sysctls: `net.ipv4.ip_forward=1`, `net.bridge.bridge-nf-call-iptables=1`, `net.bridge.bridge-nf-call-ip6tables=1`
  - Load kernel modules: `br_netfilter`, `overlay` (persist via `/etc/modules-load.d/k3s.conf`)
  - Make persistent via `/etc/sysctl.d/k3s.conf`
  - Add `k3s_prereqs` tag for selective execution
  - Update `ansible/playbooks/pis.yml` to include k3s_prereqs role
  - Test: `lsmod | grep br_netfilter` and `sysctl net.ipv4.ip_forward` should return 1

- [ ] **PR #9: Configure k3s boot parameters for cgroup support**
  - Modify `/boot/firmware/cmdline.txt` (or `/boot/cmdline.txt` on older Pis)
  - Append: `cgroup_memory=1 cgroup_enable=memory cgroup_enable=cpuset`
  - Create backup before modification: `/boot/firmware/cmdline.txt.backup`
  - Requires reboot to take effect
  - Add reboot task with confirmation prompt
  - Test after reboot: `cat /proc/cmdline | grep cgroup`
  - Risk: Medium - Requires reboot and Pi won't boot if cmdline is malformed

### Security Hardening - Raspberry Pis

- [ ] **PR #10: Harden SSH access on Raspberry Pis (key-only authentication)**
  - Create `ansible/roles/security/tasks/ssh.yml`
  - Modify `/etc/ssh/sshd_config`: `PasswordAuthentication no`, `PermitRootLogin no`, `PubkeyAuthentication yes`
  - Create backup: `/etc/ssh/sshd_config.backup`
  - Validate config with `sshd -t` before restarting
  - Restart sshd service after changes
  - Add `security` and `ssh` tags
  - Test: Attempt password auth should fail, key auth should work
  - Risk: Medium - Keep 2 SSH sessions open to avoid lockout

- [ ] **PR #11: Configure UFW firewall on Raspberry Pis**
  - Create `ansible/roles/security/tasks/ufw.yml`
  - Install `ufw` package
  - Default policy: deny incoming, allow outgoing
  - Allow SSH (22/tcp), k3s API (6443/tcp), kubelet (10250/tcp), Tailscale (41641/udp)
  - Allow from Tailscale network: `100.100.0.0/16` for k3s traffic
  - Enable UFW with `ufw enable`
  - Add `firewall` tag
  - Test: `ufw status verbose` and verify SSH still works
  - Update `ansible/playbooks/pis.yml` to include security role

### Security Hardening - Public Cloud Nodes

- [x] **PR #12: Add public cloud nodes inventory group and security variables**
  - Added `[public_nodes]` group to `ansible/hosts.ini` with all 5 public nodes
  - Nodes: pam-amd1 (VPN gateway), angela-amd2, stanley-arm1, phyllis-arm2, toby-gcp1
  - Created `ansible/group_vars/public_nodes.yml` with security config
  - Variables: `fail2ban_enabled: true`, `fail2ban_bantime: 86400`, `fail2ban_maxretry: 3`, `fail2ban_findtime: 600`
  - Variables: `ufw_enabled: true`, `ufw_ssh_rate_limit: true`

- [x] **PR #13: Deploy fail2ban to block SSH brute force attacks on public nodes** 🔥
  - **Priority: CRITICAL** - Successfully blocking 900+ attacks in first 40 minutes
  - Created `ansible/roles/fail2ban/` role structure with tasks, templates, handlers
  - Created `ansible/roles/fail2ban/templates/jail.local.j2` with systemd backend
  - Config: bantime=24h (86400s), maxretry=3, findtime=10min (600s)
  - Created `ansible/playbooks/security.yml` playbook for public nodes
  - Staged rollout: toby-gcp1 → phyllis-arm2 → stanley-arm1 → pam-amd1 → angela-amd2
  - Integrated into GitHub Actions with `security-setup` job
  - **Fix applied**: Uses systemd journald backend (not log files) for all Ubuntu systems
  - Result: 152 IPs banned, 907 attacks blocked, ~20 attacks/min blocked across all nodes

- [ ] **PR #14: Configure UFW firewall with rate limiting on public nodes**
  - Create `ansible/roles/firewall/tasks/main.yml` for public nodes
  - Install `ufw` package
  - Configure before enabling: Allow Tailscale (41641/udp) first to avoid lockout
  - Allow SSH with rate limiting: `ufw limit 22/tcp` (max 6 connections per 30 seconds)
  - Allow k3s traffic ONLY from Tailscale network: `ufw allow from 100.100.0.0/16 to any port 6443,10250 proto tcp`
  - **Special for pam-amd1**: Ensure VPN forwarding rules remain intact (check existing iptables rules)
  - Default policy: deny incoming, allow outgoing
  - Enable UFW: `ufw --force enable`
  - Add to `ansible/playbooks/security.yml`
  - Risk: Medium - Keep 2 SSH sessions open during deployment
  - Staged rollout: toby-gcp1 → phyllis → stanley → pam-amd1 → angela
  - **Extra caution on pam-amd1**: It's the VPN gateway, test Tailscale connectivity before/after
  - Test: `ufw status verbose`, verify k3s API accessible from Tailscale, SSH rate limiting works, VPN still forwards traffic

- [ ] **PR #15: Add fail2ban monitoring and daily attack reports**
  - Create `/usr/local/bin/fail2ban-report.sh` monitoring script
  - Script outputs: currently banned IPs, ban count (24h), top 10 attacker IPs (7d), recent bans (last 20)
  - Uses `fail2ban-client status sshd` and `journalctl -u fail2ban`
  - Create `ansible/roles/fail2ban/tasks/monitoring.yml`
  - Deploy to all 5 public nodes: pam-amd1, angela-amd2, stanley-arm1, phyllis-arm2, toby-gcp1
  - Add cron job: `0 9 * * * /usr/local/bin/fail2ban-report.sh` (runs at 9 AM daily)
  - Optional: Configure email delivery if `fail2ban_destemail` is set
  - Add `monitoring` tag for selective execution
  - Test: Run script manually on each node, verify output format

### Ansible Performance Optimization

- [ ] **PR #16: Optimize Ansible playbook execution with parallel strategy**
  - Add `strategy: free` to Play 2 in `ansible/vpn.yml` (Tailscale installation across multiple nodes)
  - Add `gather_facts: false` to plays that don't use ansible facts
  - Review existing playbooks: `vpn.yml`, `pis.yml`, `k3s.yml` for optimization opportunities
  - Parallel execution reduces wait time when one host is slower than others
  - Expected impact: 40-60% faster execution (3-5min → 1-2min on main branch)
  - Test: Run playbook and measure execution time before/after

- [ ] **PR #17: Add ansible.cfg with SSH performance optimizations**
  - Create `ansible/ansible.cfg` file
  - Enable SSH pipelining: `pipelining = True` (reduces SSH connections)
  - Enable ControlMaster: `ssh_args = -o ControlMaster=auto -o ControlPersist=60s`
  - Increase parallel execution: `forks = 10` (default is 5)
  - Disable host key checking for known hosts: `host_key_checking = False` (already done per-host)
  - Optional: Enable fact caching to speed up reruns
  - Expected impact: 20-30% faster SSH operations
  - Test: Run playbook with `-vv` and observe SSH connection reuse

- [x] **PR #18: Skip VPN playbook execution on pull requests**
  - Modified `.github/workflows/actions.yml` line 299
  - VPN playbook now only runs: `if: github.event_name == 'push' && github.ref == 'refs/heads/main'`
  - Dry-run check still runs on PRs for validation (line 288)
  - Reduces CI time on PRs from 3-5min to ~30s
  - Prevents redundant VPN reconfiguration on every PR

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
