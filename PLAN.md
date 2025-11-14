# PLAN: Update Raspberry Pi Firmware (Nov 2025)

## Objective

Bring michael-pi, jim-pi, and dwight-pi bootloader firmware up to the latest releases using the existing `firmware_upgrade` Ansible role.

## Steps

1. Enable the firmware upgrade role via `ansible/group_vars/pis.yml` and document the intent.
2. Run `ansible-playbooks/pis.yml` with `--tags firmware_upgrade` so the staged plays (dwight → jim → michael) sequentially apply the EEPROM/VL805 updates.
3. Re-run `rpi-eeprom-update` on all Pis to confirm the new bootloader versions and capture the output for the PR.
4. Update repo bookkeeping (TASKS/COMPLETED) and craft the PR following AXP requirements.

## Validation

- `ansible pis -i ansible/hosts.ini -b -a "rpi-eeprom-update"` reports `BOOTLOADER: up to date` for all Pis.
- Playbook run completes without failed hosts and no unexpected reboots after updates finish.
