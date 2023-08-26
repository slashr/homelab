# Homelab Architecture

My Homelab is a mix of Oracle Cloud Infrastructure and a Raspberry Pi. The Raspberry Pi is the Master Node of the Kubernetes cluster and uses a small Oracle instance to expose it's APIs to the internet using a Wireguard VPN setup. There are 3 Oracle Free Tier instances that are added to the Pi K8S Master API.

## Terraform Oracle Job
- Creates 4 Free Tier servers
- amd1 is used for Wireguard VPN setup between Pi and Oracle
- amd2, arm1, arm2 are created in order to be added as worker K8S Nodes

## Ansible Job
- Sets up a Wireguard tunnel between Pi and amd1
- Setup up K3S Agent on amd2, arm1 and arm2 and adds them to the K8S cluster

## Terraform Kubernetes Job
- Deploys ArgoCD, Cert Manager, Ingress Nginx and MetalLB on the K3S cluster
- ArgoCD then deploys a app-of-apps which consists currently of Podinfo

## GCP
- GCP SA Key is added as a environment variable in Terraform Cloud so that Terraform can access GCP infra
- The username for SSH login is the username provided in the public key in gcp/compute.tf under "ssh-keys". Can be set to any username desired

## Networking
- K3S installs by default the Traefik networking and ingress controller. Traefik takes care of exposing Services of type LoadBalancer on the RPi with the RPi private IP. It also is able to route HTTP traffic to the right Ingress. Basically it can do what ingress-nginx and metallb together so I removed them in order to simplify the setup

## Notes
### Oracle Free Tier
- 2 AMD Instances 1 CPU/1GB RAM/50GB Boot Volume each: VM.Standard.E2.1.Micro
- 4 ARM Instances 1 OCPU/6GB RAM/50GB Boot Volume each: VM.Standard.A1.Flex
- ARM instances will not have always free tag as they are flexible shape.
- ARM instances will be deleted after one-month trial. They have to be then recreated

## Diagram
https://excalidraw.com/#room=237f87c2f7158bc24c9d,ZXLWqey3dzOgnN3aM3h-oQ

## Secrets
1. HOST_IPS: List of Cloud IPs that the Github Actions Runner will add to the known_hosts file in order to avoid getting a authenticity prompt. Whenever a new Node is added or recreated, update this Secret accordingly with the new IP

## Secret Cleanup for making repo public
- Some secrets are visible in Git history. Either get rid of these individually, get rid of all git history or change whatever credentials have been exposed in the past
- These credentials include but are not limited to
  1. In k3s.yaml: K3S_TOKEN, K3S_IP
