# PLAN: Update Raspberry Pi Firmware (Nov 2025)

## Objective

Bring michael-pi, jim-pi, and dwight-pi bootloader firmware up to the latest releases using the existing `firmware_upgrade` Ansible role.

## Status

- 2025-11-14 11:06 UTC: Main-branch Actions run `19362491035` failed in the `Ansible Pis`
  job because APT could not find `libraspberrypi-bin` while executing
  `ansible/roles/firmware_upgrade/tasks/main.yml`. Debian 13 on the Raspberry Pis does
  not ship this package, so enabling the role exposed the missing dependency.

## Steps

1. Adjust `ansible/group_vars/pis.yml` to drop `libraspberrypi-bin` (and document why) so the firmware role only installs packages that exist in Debian’s repos (`rpi-eeprom` and `raspi-config`).
2. Teach the firmware role to detect whether `vcgencmd` exists and skip the bootloader-version
   capture tasks (with a helpful debug message) when it does not, so dropping `libraspberrypi-bin`
   no longer causes later failures.
3. Leave `firmware_upgrade_enabled: true` so the next GitHub Actions run re-attempts the staged firmware rollout across dwight → jim → michael.
4. Update `TASKS.md` to reflect the follow-up task/PR for fixing the package set so bookkeeping stays accurate under AXP.
5. Once GitHub Actions completes successfully, verify `rpi-eeprom-update` output (captured in CI logs) shows “BOOTLOADER: up to date” for all Pis, then move the task entry to `COMPLETED.md`.

## Validation

- `ansible-playbook --private-key … -i ansible/hosts.ini playbooks/pis.yml --tags firmware_upgrade --limit pis --check` (run by Actions) succeeds without missing-package errors.
- Post-run `rpi-eeprom-update` output in workflow logs shows the latest bootloader versions for michael, jim, and dwight.
