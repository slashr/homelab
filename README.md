[![latest release](https://img.shields.io/github/release/slashr/homelab)](https://github.com/slashr/homelab/releases)
[![license](https://img.shields.io/github/license/slashr/homelab)](https://github.com/slashr/homelab/blob/main/license.txt)
[![repo size](https://img.shields.io/github/repo-size/slashr/homelab)](https://github.com/slashr/homelab)
[![Build Status](https://img.shields.io/github/actions/workflow/status/slashr/homelab/actions.yml)](https://github.com/slashr/homelab/actions/workflows/actions.yml)
[![commits since last release](https://img.shields.io/github/commits-since/slashr/homelab/latest)](https://github.com/slashr/homelab/commits/main)
[![last commit](https://img.shields.io/github/last-commit/slashr/homelab)](https://github.com/slashr/homelab/commits/main)
[![commit activity](https://img.shields.io/github/commit-activity/y/slashr/homelab)](https://github.com/slashr/homelab/commits/main)

# Homelab Architecture

My Homelab is a mix of Oracle Cloud Infrastructure and three Raspberry Pis. The Raspberry Pi is the Master Node of the Kubernetes cluster and uses a small Oracle instance to expose it's APIs to the internet using a Wireguard VPN setup.

## Terraform Oracle Job
- Creates 4 Free Tier servers
- amd1 is used for Wireguard VPN setup between Pi and Oracle
- amd2, arm1, arm2 are created in order to be added as worker K8S Nodes

## Ansible Job
- Sets up a Wireguard tunnel between Pi and amd1
- Setup up K3S Agent on amd2, arm1 and arm2 and adds them to the K8S cluster
- Cluster version is defined in `ansible/group_vars/all.yml`. Rerun
  `ansible/k3s.yml` after changing the version to upgrade all nodes.

## Terraform Kubernetes Job
- Deploys ArgoCD, Cert Manager, Ingress Nginx and MetalLB on the K3S cluster
- ArgoCD then deploys a app-of-apps which consists currently of Podinfo

## GCP
- GCP SA Key is added as a environment variable in Terraform Cloud so that Terraform can access GCP infra
- The `ssh_username` and `ssh_public_key` variables define the login user and SSH key used for the instance
- The `gcp/variables.tf` file defines variables for `project`, `region`, `zone`, `machine_type`, `ssh_username`, and `ssh_public_key` to customize the deployment

## Networking
- K3S installs by default the Traefik networking and ingress controller. Traefik takes care of exposing Services of type LoadBalancer on the RPi with the RPi private IP. It also is able to route HTTP traffic to the right Ingress. Basically it can do what ingress-nginx and metallb together so I removed them in order to simplify the setup
- Tailscale is used to create a meshnetwork between all servers. Tailscale auth key is added as TAILSCALE_JOIN_KEY in Github Secrets. Then it is set as TAILSCALE_JOIN_KEY env for the Ansible job inside github workflow actions.yml. And finally it is referred to inside k3s.yaml for the --vpn-auth flag when initializing k3s on the main and nodes.

## Notes
### Oracle Free Tier
- 2 AMD Instances 1 CPU/1GB RAM/50GB Boot Volume each: VM.Standard.E2.1.Micro
- 4 ARM Instances 1 OCPU/6GB RAM/50GB Boot Volume each: VM.Standard.A1.Flex
- ARM instances will not have always free tag as they are flexible shape.
- ARM instances will be deleted after one-month trial. They have to be then recreated

## Diagram
https://excalidraw.com/#room=237f87c2f7158bc24c9d,ZXLWqey3dzOgnN3aM3h-oQ

## Secrets

## Servers
- michael-pi        Raspberry Pi 5 8GB 1    192.168.1.100      172.20.60.100
- jim-pi            Raspberry Pi 5 8GB 2    192.168.1.101      172.20.60.101 
- dwight-pi         Raspberry Pi 4 8GB      192.168.1.102      172.20.60.102

## TODO
- Automate/codify Tailscale manual modifications:
  - Backup Access Control List including Pod IP Auto-approve(10.42.0.0/16), Custom Node IP range (100.100.0.0/16), Groups and Tags definitions

## Roadmap
- 3 proxmox servers
- Bitwarden Edit: vaultwarden password manager
- Code server vscode in a browser
- Nextcloud I only use it for calendar
- TrueNas just storage
- Immich photo backups from phone
- Twingate vpn (for family with reduced access**)
- NTFY notifications
- Uptime Kuma checks if things are running, and notifies me via ntfy
- Transmission
- Jellyfin
- Jellyseerr
- Sonarr
- Radarr
- Prowlarr to connect jellyseer and the others
- Plex
- Snapdrop basically airdrop
- Syncthing to sync folders from personal computer to nas
- Handbrake (docker container) to transcode 
- Dashdot widgets for homarr
- Homarr home page
- Cloudflare tunnel for access

Ref: https://www.reddit.com/r/selfhosted/comments/1dhttjy/bored_with_my_homelab/?share_id=UPxrbGis6njRtFiR35M1v&utm_content=2&utm_medium=ios_app&utm_name=ioscss&utm_source=share&utm_term=1


## Contributing

This project uses [pre-commit](https://pre-commit.com/) to lint Terraform, Ansible, and YAML files.

### Setup
1. Install pre-commit with `pip install pre-commit`.
2. Run `pre-commit install` once to add the git hooks.

### Running the checks
Execute `pre-commit run --all-files` to run all hooks on the repository.
