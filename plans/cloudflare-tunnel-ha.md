# PLAN: Cloudflare Tunnel HA for Service Ingress

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds. Maintain this plan per the requirements documented in `PLANS.md`.

## Purpose / Big Picture

Currently, all public services (argo.shrub.dev, signoz.shrub.dev, hey.shrub.dev, etc.) route through a single public IP on pam-amd1 (130.61.64.164). If pam-amd1 becomes unavailable, all services become unreachable even though the k3s cluster may still be running on other nodes.

After this change, all public-facing services will route through Cloudflare Tunnel with three redundant cloudflared instances running on pam-amd1, angela-amd2, and toby-gcp1. If any single node fails, Cloudflare automatically routes traffic to the remaining healthy nodes. Users will access services exactly as before (same URLs), but with automatic failover and the added benefit of Cloudflare's DDoS protection.

## Progress

- [x] Create Terraform module for Cloudflare Tunnel
- [x] Add module to kubernetes/cluster.tf
- [x] Create Ansible role for cloudflared deployment
- [x] Create Ansible playbook for deployment
- [ ] Add Cloudflare account_id and zone_id variables to Terraform Cloud
- [ ] Apply Terraform to create tunnel, config, and DNS records
- [ ] Get tunnel token from Terraform output
- [ ] Deploy cloudflared to pam-amd1, angela-amd2, toby-gcp1
- [ ] Update ArgoCD ingress to remove external-dns annotations
- [ ] Verify failover by stopping cloudflared on one node
- [ ] Optional: Remove direct inbound firewall rules for 80/443

## Surprises & Discoveries

- (2025-12-22) The Terraform Cloudflare provider supports creating tunnels, tunnel configs, and DNS records via `cloudflare_tunnel`, `cloudflare_tunnel_config`, and `cloudflare_record` resources. This enables full GitOps instead of manual CLI commands.

## Decision Log

- Decision: Use Cloudflare Tunnel instead of DNS round-robin or load balancer
  Rationale: Cloudflare Tunnel provides automatic health-based failover, requires no inbound ports, includes DDoS protection, and is free. DNS round-robin lacks health checks; external load balancers add cost and complexity.
  Date/Author: 2025-12-22 / slashr

- Decision: Run cloudflared on the three public nodes (pam, angela, toby) rather than inside k3s
  Rationale: Running as a systemd service on the host is simpler, survives k3s issues, and these nodes already have public IPs and stable uptime. Running inside k3s would add complexity with pod scheduling and credentials management.
  Date/Author: 2025-12-22 / slashr

- Decision: Route tunnel traffic to ingress-nginx ClusterIP rather than individual services
  Rationale: Reuses existing ingress configuration, TLS termination, and routing rules. No need to duplicate service routing logic in cloudflared config.
  Date/Author: 2025-12-22 / slashr

- Decision: Use Terraform to create tunnel instead of CLI
  Rationale: Full GitOps approach - tunnel, config, and DNS records all managed as code. Tunnel token output can be passed to Ansible. More reproducible and auditable than manual CLI commands.
  Date/Author: 2025-12-22 / Claude

## Outcomes & Retrospective

(To be updated upon completion)

## Context and Orientation

This homelab runs a hybrid k3s cluster spanning Oracle Cloud (pam-amd1, angela-amd2, stanley-arm1, phyllis-arm2), GCP (toby-gcp1), and Raspberry Pis behind CGNAT. The cluster uses:

- **ingress-nginx**: Handles HTTP/HTTPS ingress, deployed as a DaemonSet, listening on node ports
- **external-dns**: Syncs Kubernetes Ingress hostnames to Cloudflare DNS
- **cert-manager**: Provisions Let's Encrypt certificates via Cloudflare DNS-01 challenge
- **Tailscale**: Mesh VPN connecting all nodes, used for inter-node communication and SSH access

Current DNS configuration points all service hostnames to pam-amd1's public IP:

    argo.shrub.dev   → 130.61.64.164 (A record)
    signoz.shrub.dev → 130.61.64.164 (A record)
    hey.shrub.dev    → 130.61.64.164 (A record)

Traffic flow today:

    Internet → pam-amd1:443 → ingress-nginx → k8s Service → Pod

Traffic flow after this change:

    Internet → Cloudflare Edge → cloudflared (pam OR angela OR toby) → ingress-nginx → k8s Service → Pod

Key files and directories:

- `terraform-modules/cloudflare-tunnel/` — Terraform module for tunnel management
- `ansible/roles/cloudflared/` — Ansible role for cloudflared installation
- `ansible/playbooks/cloudflared.yml` — Playbook for deploying cloudflared
- `kubernetes/cluster.tf` — Main Terraform config that includes the tunnel module

## Architecture

### Terraform Module (`terraform-modules/cloudflare-tunnel/`)

The module manages:
1. `cloudflare_tunnel` - Creates the tunnel with a random secret
2. `cloudflare_tunnel_config` - Defines ingress rules (hostnames → localhost:80)
3. `cloudflare_record` - Creates CNAME records pointing to the tunnel

Outputs:
- `tunnel_id` - UUID of the tunnel
- `tunnel_token` - Token for cloudflared authentication (sensitive)
- `tunnel_cname` - CNAME target for DNS records

### Ansible Role (`ansible/roles/cloudflared/`)

The role:
1. Adds Cloudflare APT repository
2. Installs cloudflared package
3. Deploys systemd service using `--token` flag
4. Enables and starts the service

The role uses the simpler `--token` authentication (single value) instead of credentials JSON file.

## Plan of Work

### Milestone 1: Configure Terraform Cloud Variables

Add the following variables to the kubernetes workspace in Terraform Cloud:

| Variable | Type | Description |
|----------|------|-------------|
| `cloudflare_account_id` | String | Cloudflare account ID |
| `cloudflare_zone_id` | String | Zone ID for shrub.dev |

To find these values:
```bash
# Account ID: Cloudflare dashboard → any domain → Overview → right sidebar
# Zone ID: Cloudflare dashboard → shrub.dev → Overview → right sidebar
```

### Milestone 2: Apply Terraform

```bash
cd kubernetes
terraform init   # Download cloudflare provider
terraform plan   # Verify changes
terraform apply  # Create tunnel, config, and DNS records
```

This creates:
- Tunnel named `homelab-ha`
- Ingress rules routing `argo.shrub.dev` → `http://localhost:80`
- CNAME record: `argo.shrub.dev` → `<tunnel-id>.cfargotunnel.com`

### Milestone 3: Get Tunnel Token

```bash
terraform output -raw cloudflare_tunnel_token
```

Store this token securely for Ansible deployment.

### Milestone 4: Deploy Cloudflared

```bash
# Set the tunnel token from Terraform output
export CLOUDFLARE_TUNNEL_TOKEN=$(cd kubernetes && terraform output -raw cloudflare_tunnel_token)

# Deploy to public nodes
ansible-playbook -i ansible/hosts.ini ansible/playbooks/cloudflared.yml \
  -e "cloudflared_tunnel_token=$CLOUDFLARE_TUNNEL_TOKEN"
```

### Milestone 5: Update Ingress Annotations

Remove external-dns annotations from ArgoCD ingress since DNS is now managed by Terraform:

Edit `terraform-modules/argo-cd/values.yaml`:
```yaml
server:
  ingress:
    annotations:
      # Remove these lines:
      # external-dns.alpha.kubernetes.io/hostname: argo.shrub.dev
      # external-dns.alpha.kubernetes.io/target: 130.61.64.164
      cert-manager.io/cluster-issuer: letsencrypt-prod
```

### Milestone 6: Verify Failover

```bash
# Check tunnel status in Cloudflare dashboard
# Should show 3 connections (one per node)

# Test service access
curl -I https://argo.shrub.dev

# Test failover
ssh pam-amd1 'sudo systemctl stop cloudflared'
curl -I https://argo.shrub.dev  # Should still work
ssh pam-amd1 'sudo systemctl start cloudflared'
```

### Milestone 7: Optional Hardening

After confirming tunnel works, optionally remove direct inbound access:

```bash
# On each public node (careful - ensure tunnel is working first!)
sudo ufw delete allow 80/tcp
sudo ufw delete allow 443/tcp
```

## Validation and Acceptance

Acceptance criteria:

1. Cloudflare dashboard shows 3 active tunnel connections
2. All services (argo.shrub.dev) are accessible via HTTPS
3. Stopping cloudflared on any single node does not cause service outage
4. DNS records show CNAME to `<uuid>.cfargotunnel.com` instead of A records

Verification commands:

```bash
# Check DNS
dig argo.shrub.dev
# Expected: CNAME to <uuid>.cfargotunnel.com

# Check service
curl -sI https://argo.shrub.dev | head -1
# Expected: HTTP/2 200

# Check failover
ssh pam-amd1 'sudo systemctl stop cloudflared'
curl -sI https://argo.shrub.dev | head -1
# Expected: HTTP/2 200 (still works)
ssh pam-amd1 'sudo systemctl start cloudflared'
```

## Idempotence and Recovery

Both Terraform and Ansible are idempotent — running them multiple times produces the same result.

If a node fails:
1. Other nodes continue serving traffic automatically
2. Fix the node and restart cloudflared: `sudo systemctl start cloudflared`
3. Cloudflare automatically adds it back to the pool

To rollback to direct A records:
1. Remove the cloudflare-tunnel module from cluster.tf
2. Run `terraform apply` to destroy tunnel and DNS records
3. external-dns will recreate A records from Ingress annotations
4. Stop cloudflared: `ansible public_nodes -m service -a "name=cloudflared state=stopped"`

## Artifacts

Files created:

```
terraform-modules/cloudflare-tunnel/
├── main.tf           # Tunnel, config, and DNS resources
├── variables.tf      # Input variables
└── outputs.tf        # Tunnel token and ID outputs

ansible/roles/cloudflared/
├── tasks/main.yml           # Installation tasks
├── templates/cloudflared.service.j2  # Systemd service
├── handlers/main.yml        # Restart handler
└── defaults/main.yml        # Default variables

ansible/playbooks/cloudflared.yml  # Deployment playbook

kubernetes/
├── provider.tf      # Added cloudflare provider
├── variables.tf     # Added account_id and zone_id
├── cluster.tf       # Added cloudflare-tunnel module
└── outputs.tf       # Tunnel token output
```

## Interfaces and Dependencies

External dependencies:
- Cloudflare account with shrub.dev zone
- Cloudflare API token with Zone:DNS:Edit and Account:Cloudflare Tunnel:Edit permissions
- Terraform Cloud workspace with cloudflare variables

Internal dependencies:
- ingress-nginx running as DaemonSet with hostPort 80/443
- `[public_nodes]` group in `ansible/hosts.ini`

---

Plan history:

- (2025-12-22) Initial plan created based on discussion of CGNAT bypass and service HA requirements.
- (2025-12-22) Updated to GitOps approach using Terraform instead of manual CLI commands.
