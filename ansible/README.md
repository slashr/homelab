# Ansible

## Playbooks

### k3s.yml

Deploys k3s master on michael-pi and joins worker nodes from Oracle Cloud, GCP, and Raspberry Pis.

### pis.yml

Configures all Raspberry Pi nodes with common settings, security hardening, network stability fixes, and k3s prerequisites. Uses parallel execution strategy for efficient deployment across all Pis.

### tailscale.yml

Installs and configures Tailscale on all nodes (Pis, Oracle workers, GCP workers). Enables Tailscale SSH and authenticates nodes using the `TAILSCALE_JOIN_KEY` environment variable.

### security.yml

Deploys security hardening (fail2ban and UFW firewall) to public cloud nodes. Uses staged rollout for safe deployment.

**Prerequisites for cross-node pod networking:**

- Tailscale must be configured with subnet route advertisement (each node advertises its pod CIDR)
- k3s must be installed with `--vpn-auth` flag to enable Flannel Tailscale backend
- UFW rules allow pod/service CIDRs (10.42.0.0/16, 10.43.0.0/16) for firewall traversal

Without proper Tailscale route advertisement, UFW rules alone will not enable cross-node communication. The security role depends on the Tailscale and k3s roles being properly configured.

### swap.yml

Configures swap on low-memory nodes (micro_nodes group) to prevent OOM kills.

## Debian Release Upgrades

* The `roles/debian_upgrade` role rewrites APT sources, runs a dist-upgrade, cleans up packages, and reboots the node so we can move Pis between Debian releases via Ansible.
* `group_vars/pis.yml` controls `debian_upgrade_enabled`, `debian_upgrade_target_release`, and
  `debian_upgrade_target_version` for the entire Raspberry Pi fleet. Flip `debian_upgrade_enabled` to `true`
  and bump the target values (e.g., to Debian 13) when you are ready to roll the cluster forward; set it back
  to `false` once all Pis converge.
* To run the upgrade in isolation, trigger the main `actions.yml` workflow manually (`workflow_dispatch`).
  The CI run reuses the same playbook and applies the release-upgrade tasks automatically across all Pis.

## Firmware Upgrades

* The `roles/firmware_upgrade` role wraps `rpi-eeprom-update` so we can update the Pi bootloader/VL805 firmware via GitOps.
* `group_vars/pis.yml` exposes `firmware_upgrade_enabled`, `firmware_upgrade_reboot_timeout`, and the package
  list that should be present before running the update. Set the flag to `true` when you want to apply the
  latest EEPROM image across the fleet, then revert it to `false` after a successful rollout.
* Firmware upgrades respect the staged dwight → jim → michael rollout defined in `playbooks/pis.yml`.
