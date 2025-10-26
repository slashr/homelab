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

## Encrypting and Decrypting files
- Files inside ansible/confs are encrypted with ansible-vault. In order to decrypt it, run `ansible-vault decrypt confs/iptables.conf` and enter the vault password (saved on BitWarden)
- Make modifications to the files as needed
- Encrypt them again using `ansible-vault encrypt confs/iptables.conf`
- To change the vault password, simply use a new password when encrypting again and also update the password in Github Actions
