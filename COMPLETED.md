# Completed Tasks

This document tracks all completed PRs and their implementation details for historical reference.

---

## Raspberry Pi Configuration

### ✅ PR #1: Add Raspberry Pi inventory group and configuration variables

**Completed:** Early 2024  
**Branch:** N/A

- Added `[pis]` group to `ansible/hosts.ini` with michael-pi, jim-pi, dwight-pi
- Created `ansible/group_vars/pis.yml` with shared configuration
- Configured Tailscale IPs (100.100.1.x), ansible_user, python interpreter paths
- Base packages list, DNS servers, WiFi settings all centralized

---

### ✅ PR #2: Add Ansible dry-run checks to GitHub Actions

**Completed:** Early 2024  
**Branch:** N/A

- Added dry-run validation in `.github/workflows/actions.yml` (line 270)
- Runs `ansible-playbook --check` on PRs before merge
- Only runs if Pi-related files changed (reduces CI time)
- Shows diff preview in PR summary for review

---

### ✅ PR #3: Install essential system packages on Raspberry Pis

**Completed:** Early 2024  
**Branch:** N/A

- Created `ansible/roles/common/tasks/main.yml`
- Installs: vim, curl, htop, iotop, git, tmux via apt
- Uses `base_packages` variable from group_vars for flexibility
- Tagged with `packages` for selective execution

---

### ✅ PR #4: Configure timezone, locale, and automatic security updates

**Completed:** Early 2024  
**Branch:** N/A

- Set timezone to Europe/Berlin, locale to en_GB.UTF-8
- Installed and enabled unattended-upgrades for automatic security patches
- Created custom MOTD showing hostname, IP, OS version, kernel
- All in `ansible/roles/common/tasks/main.yml`, tagged with `system`

---

### ✅ PR #5: Fix WiFi power save causing network latency and retries 🔥

**Completed:** Early 2024  
**Branch:** N/A  
**Priority:** CRITICAL - Fixed jim-pi latency (8000ms → <20ms), reduced retries (4325 → <100)

- Implemented in `ansible/roles/network/tasks/main.yml`
- Detects NetworkManager or dhcpcd and configures accordingly
- NetworkManager: Creates `/etc/NetworkManager/conf.d/wifi-powersave.conf` with `wifi.powersave = 2`
- dhcpcd: Creates `/etc/dhcpcd.enter-hook` to run `iwconfig wlan0 power off`
- Immediately disables at runtime: `iwconfig wlan0 power off`
- Tagged with `wifi` for targeted deployment

---

### ✅ PR #6: Configure DNS with AdGuard on dwight-pi

**Completed:** Early 2024  
**Branch:** N/A

- Primary DNS: 100.100.1.102 (dwight-pi AdGuard via Tailscale)
- Fallbacks: 1.1.1.1 (Cloudflare), 8.8.8.8 (Google)
- Template: `ansible/roles/network/templates/resolv.conf.j2` → `/etc/resolv.conf`
- Prevents overwrite by NetworkManager and dhcpcd
- Provides ad-blocking and works when Pis are remote from LAN

---

### ✅ PR #7: Configure NTP time synchronization

**Completed:** Early 2024  
**Branch:** N/A

- Enables and starts `systemd-timesyncd` service
- Configures NTP servers: 0-3.pool.ntp.org, fallback to Cloudflare/Google time servers
- Config file: `/etc/systemd/timesyncd.conf`
- Ensures accurate timestamps for logs and scheduled tasks
- Tagged with `ntp` in `ansible/roles/network/tasks/main.yml`

---

### ✅ PR #8: Add k3s runtime prerequisites role for Raspberry Pis

**Completed:** Early 2024  
**Branch:** N/A

- Created `ansible/roles/k3s_prereqs/tasks/main.yml` with runtime configuration
- Configured sysctls: `net.ipv4.ip_forward=1`, `net.bridge.bridge-nf-call-iptables=1`, `net.bridge.bridge-nf-call-ip6tables=1`
- Load kernel modules: `br_netfilter`, `overlay` (persisted via `/etc/modules-load.d/k3s.conf`)
- Made persistent via `/etc/sysctl.d/k3s.conf`
- Added `k3s_prereqs` tag for selective execution
- Updated `ansible/playbooks/pis.yml` to include k3s_prereqs role (lines 9, 18, 27)
- Deployed and verified on all 3 Raspberry Pis (michael-pi, jim-pi, dwight-pi)

---

### ✅ PR #9: Configure k3s boot parameters for cgroup support

**Completed:** Early 2024  
**Branch:** N/A

- Created `ansible/roles/k3s_prereqs/tasks/cgroup_boot.yml` for boot parameter configuration
- Detects correct cmdline.txt path (`/boot/firmware/cmdline.txt` for Pi 4+, `/boot/cmdline.txt` for older)
- Appends: `cgroup_memory=1 cgroup_enable=memory cgroup_enable=cpuset`
- Creates backup before modification, skips if already present
- Verified active on all 3 Raspberry Pis after reboot:
  - dwight-pi: ✅ cgroup parameters active (Pi 4, uses `/boot/cmdline.txt`)
  - jim-pi: ✅ cgroup parameters active (Pi 5, uses `/boot/firmware/cmdline.txt`)
  - michael-pi: ✅ cgroup parameters active (Pi 5, uses `/boot/firmware/cmdline.txt`)
- cgroup2 filesystem properly mounted on all nodes

### ✅ PR #29: Enable Raspberry Pi firmware upgrade via Ansible

**Completed:** November 2025  
**Branch:** `task-030-pi-firmware-upgrade`

- Turned on the `firmware_upgrade` role by setting `firmware_upgrade_enabled: true` in `ansible/group_vars/pis.yml` so CI/CD can manage EEPROM/VL805 updates.
- Documented the rollout intent and validation steps in `PLAN.md` (Nov 2025 firmware refresh).
- Added a Raspberry Pi Maintenance section to `TASKS.md` to track future firmware or hardware upkeep under AXP.

### ✅ PR #30: Fix Raspberry Pi firmware package set

**Completed:** November 2025  
**Branch:** `task-031-firmware-package`

- Removed `libraspberrypi-bin` from `firmware_upgrade_packages` so Debian 13 hosts stop failing the firmware playbook on APT.
- Added runtime detection/guarding around `vcgencmd` in `ansible/roles/firmware_upgrade/tasks/main.yml`, including helpful debug output when the binary is missing.
- Updated `PLAN.md`/`TASKS.md` to capture the follow-up plan and close out the Raspberry Pi maintenance work under AXP.

---

## Security Hardening - Raspberry Pis

### ✅ PR #10: Harden SSH access on Raspberry Pis (key-only authentication)

**Completed:** Early 2024  
**Branch:** N/A

- Created `ansible/roles/security/` role with SSH hardening
- Template `/etc/ssh/sshd_config` with: `PasswordAuthentication no`, `PermitRootLogin no`, `PubkeyAuthentication yes`
- Creates backup before modification (`/etc/ssh/sshd_config.backup`)
- Validates config with `sshd -t` before applying
- Handler restarts sshd service after changes
- Tagged with `security` and `ssh` for selective execution
- Deployed and verified on all 3 Raspberry Pis (dwight-pi, jim-pi, michael-pi)
- Additional hardening: `MaxAuthTries 3`, `ClientAliveInterval 300`, disabled X11Forwarding

---

### ✅ PR #277: Configure UFW firewall on Raspberry Pis

**Completed:** October 2025  
**Branch:** `feat/ufw-firewall-raspberry-pis`

- Created `ansible/roles/security/tasks/ufw.yml`
- Install `ufw` package
- Default policy: deny incoming, allow outgoing
- Allow SSH (22/tcp), k3s API (6443/tcp), kubelet (10250/tcp), Tailscale (41641/udp)
- Allow DNS (53), HTTP (80), HTTPS (443) from both:
  - Local network: `192.168.1.0/24`
  - Tailscale network: `100.100.0.0/16`
- Used variables instead of hardcoded CIDRs
- Deployed and verified on all 3 Raspberry Pis
- No dwight-specific special handling (portable configuration)

---

## Security Hardening - Public Cloud Nodes

### ✅ PR #12: Add public cloud nodes inventory group and security variables

**Completed:** October 2025  
**Branch:** N/A

- Added `[public_nodes]` group to `ansible/hosts.ini` (lines 23-28) with all 5 public nodes
- Nodes: pam-amd1 (VPN gateway), angela-amd2, stanley-arm1, phyllis-arm2, toby-gcp1
- Created `ansible/group_vars/public_nodes.yml` with security config
- Variables: `fail2ban_enabled: true`, `fail2ban_bantime: 86400`, `fail2ban_maxretry: 3`, `fail2ban_findtime: 600`
- Variables: `ufw_enabled: true`, `ufw_ssh_rate_limit: true`
- Inventory group available for security playbook targeting

---

### ✅ PR #13: Deploy fail2ban to block SSH brute force attacks on public nodes 🔥

**Completed:** October 2025  
**Branch:** N/A  
**Priority:** CRITICAL - Successfully deployed across all 5 public nodes

- Created `ansible/roles/fail2ban/` role structure (tasks, templates, handlers)
- Created `ansible/roles/fail2ban/tasks/main.yml` for installation
- Created `ansible/roles/fail2ban/templates/jail.local.j2` with SSH jail config
- Config: bantime=24h (86400s), maxretry=3, findtime=10min (600s)
- Created `ansible/roles/fail2ban/handlers/main.yml` to restart fail2ban
- Created `ansible/playbooks/security.yml` playbook for staged rollout
- Staged rollout order: toby-gcp1 → phyllis-arm2 → stanley-arm1 → pam-amd1 → angela-amd2
- Deployed and verified: pam-amd1 has 87 IPs banned, 446 total failed attempts blocked
- Result: Successfully blocking SSH brute force attacks across all public nodes

---

### ✅ PR #278: Configure UFW firewall with rate limiting on public nodes

**Completed:** October 2025  
**Branch:** `feat/ufw-firewall-public-nodes`

- Created `ansible/roles/firewall/tasks/main.yml` for public nodes
- Install `ufw` package
- Configure before enabling: Allow Tailscale (41641/udp) first to avoid lockout
- Allow SSH with rate limiting: `ufw limit 22/tcp` (max 6 connections per 30 seconds)
- Allow k3s traffic ONLY from Tailscale network: `100.100.0.0/16`
- Special handling for pam-amd1 VPN gateway (preserve NAT rules)
- Default policy: deny incoming, allow outgoing, allow routed
- Used variables: `tailscale_network_cidr`, `vpn_gateway_ip`
- Added apt lock wait logic to fail2ban role
- Staged rollout: toby-gcp1 → phyllis → stanley → pam-amd1 → angela
- Result: toby-gcp1 verified with 90 IPs already banned by fail2ban

---

## Ansible Performance Optimization

### ✅ PR #18: Skip VPN playbook execution on pull requests

**Completed:** October 2025  
**Branch:** N/A

- Modified `.github/workflows/actions.yml` line 299
- VPN playbook now only runs: `if: github.event_name == 'push' && github.ref == 'refs/heads/main'`
- Dry-run check still runs on PRs for validation (line 288)
- Reduces CI time on PRs from 3-5min to ~30s
- Prevents redundant VPN reconfiguration on every PR

---

## CI/CD Improvements

### ✅ PR #23: Add k3s playbook dry-run validation

**Completed:** November 2025  
**Branch:** N/A

- Extended `.github/workflows/actions.yml` dry-run logic to include `k3s.yml` whenever k3s files change.
- Added `k3s-master-config.yaml` and all k3s role paths to the workflow path filter so PRs touching control-plane logic run syntax checks automatically.
- Runs `ansible-playbook --check` for `k3s.yml` on pull requests, matching coverage already in place for vpn.yml and pis.yml.

### ✅ PR #24: Optimize GitHub Actions caching strategy

**Completed:** November 2025  
**Branch:** N/A

- Standardized Terraform cache keys to hash every `.tf` file and lockfile, ensuring plugin caches invalidate whenever infrastructure code changes.
- Added caching for Ansible collections at `~/.ansible/collections` keyed by `ansible/requirements.yml`, cutting Pi playbook setup time by ~30%.
- Ensured each workflow job warms caches before `terraform init`/`ansible-galaxy install`, reducing overall CI runtime.

### ✅ PR #25: Add pre-commit hooks for sensitive file detection

**Completed:** November 2025  
**Branch:** N/A

- Added `detect-secrets` (with repo baseline) and `gitleaks` to `.pre-commit-config.yaml` to prevent secret leaks.
- Introduced a custom `check-ansible-vault` hook backed by `scripts/check-vault-encrypted.sh` to block commits containing decrypted vault files.
- Hooks run locally and in CI so sensitive data never lands in git history.

---

## Total Completed: 19 PRs

**Raspberry Pi Configuration:** 9 PRs  
**Security Hardening (Pis):** 2 PRs  
**Security Hardening (Public Nodes):** 3 PRs  
**Ansible Performance:** 1 PR  
**Network Configuration:** 1 PR (included above)  
**CI/CD Improvements:** 3 PRs
