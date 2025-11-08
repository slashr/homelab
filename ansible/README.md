# Ansible

## Raspberry Pi GitOps Migration

**See:** `../RPI_GITOPS_PLAN.md` for the comprehensive plan to bring all Raspberry Pi configuration under GitOps management.

**Status:** Planning complete - ready for implementation via sequential PRs.

## Playbooks

### vpn.yml

Configures Tailscale VPN mesh network across all nodes and sets up iptables forwarding on the VPN gateway (pam-amd1).

### k3s.yml

Deploys k3s master on michael-pi and joins worker nodes from Oracle Cloud, GCP, and Raspberry Pis.

### pis.yml (Coming Soon)

Configures all Raspberry Pi nodes with common settings, security hardening, network stability fixes, and k3s prerequisites.

## Debian Release Upgrades

- The `roles/debian_upgrade` role rewrites APT sources, runs a dist-upgrade, cleans up packages, and reboots the node so we can move Pis between Debian releases via Ansible.
- `group_vars/pis.yml` controls `debian_upgrade_enabled`, `debian_upgrade_target_release`, and
  `debian_upgrade_target_version` for the entire Raspberry Pi fleet. Flip `debian_upgrade_enabled` to `true`
  and bump the target values (e.g., to Debian 13) when you are ready to roll the cluster forward; set it back
  to `false` once all Pis converge.
- To run the upgrade in isolation, trigger the main `actions.yml` workflow manually (`workflow_dispatch`).
  The CI run reuses the same playbook and applies the release-upgrade tasks automatically across all Pis.

## Firmware Upgrades

- The `roles/firmware_upgrade` role wraps `rpi-eeprom-update` so we can update the Pi bootloader/VL805 firmware via GitOps.
- `group_vars/pis.yml` exposes `firmware_upgrade_enabled`, `firmware_upgrade_reboot_timeout`, and the package
  list that should be present before running the update. Set the flag to `true` when you want to apply the
  latest EEPROM image across the fleet, then revert it to `false` after a successful rollout.
- Firmware upgrades respect the staged dwight → jim → michael rollout defined in `playbooks/pis.yml`.

## Encrypting and Decrypting files

- Files inside ansible/confs are encrypted with ansible-vault. In order to decrypt it, run `ansible-vault decrypt confs/iptables.conf` and enter the vault password (saved on BitWarden)
- Make modifications to the files as needed
- Encrypt them again using `ansible-vault encrypt confs/iptables.conf`
- To change the vault password, simply use a new password when encrypting again and also update the password in Github Actions
