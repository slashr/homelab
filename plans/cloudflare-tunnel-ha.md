# PLAN: Cloudflare Tunnel HA for Service Ingress

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds. Maintain this plan per the requirements documented in `PLANS.md`.

## Purpose / Big Picture

Currently, all public services (argo.shrub.dev, signoz.shrub.dev, hey.shrub.dev, etc.) route through a single public IP on pam-amd1 (130.61.64.164). If pam-amd1 becomes unavailable, all services become unreachable even though the k3s cluster may still be running on other nodes.

After this change, all public-facing services will route through Cloudflare Tunnel with three redundant cloudflared instances running on pam-amd1, angela-amd2, and toby-gcp1. If any single node fails, Cloudflare automatically routes traffic to the remaining healthy nodes. Users will access services exactly as before (same URLs), but with automatic failover and the added benefit of Cloudflare's DDoS protection.

## Progress

- [ ] Create Cloudflare Tunnel named `homelab-ha`
- [ ] Create Ansible role for cloudflared deployment
- [ ] Deploy cloudflared to pam-amd1, angela-amd2, toby-gcp1
- [ ] Configure tunnel ingress rules for all services
- [ ] Migrate DNS records from A records to CNAME (tunnel)
- [ ] Verify failover by stopping cloudflared on one node
- [ ] Optional: Remove direct inbound firewall rules for 80/443

## Surprises & Discoveries

(To be updated during implementation)

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

- `ansible/roles/` — Ansible roles for node configuration
- `ansible/hosts.ini` — Inventory with node groups including `[public_nodes]`
- `terraform-modules/external-dns/` — ExternalDNS Helm deployment
- `terraform-modules/argo-cd/values.yaml` — ArgoCD ingress configuration

Cloudflare account is already authenticated via `cloudflared tunnel login` with credentials stored at `~/.cloudflared/cert.pem`.

## Plan of Work

### Milestone 1: Create Tunnel and Credentials

Create a Cloudflare Tunnel named `homelab-ha`. This generates a credentials JSON file that must be distributed to all nodes running cloudflared. The tunnel ID and credentials are sensitive and should be stored securely.

1. Run `cloudflared tunnel create homelab-ha` to create the tunnel
2. Note the tunnel UUID and credentials file path
3. Store credentials securely (Ansible Vault or similar)

### Milestone 2: Create Ansible Role for cloudflared

Create an Ansible role that installs and configures cloudflared on target nodes. The role will:

1. Install cloudflared package from Cloudflare's repository
2. Create `/etc/cloudflared/` directory
3. Deploy credentials JSON file (from Ansible Vault)
4. Deploy config.yml with ingress rules
5. Install and enable systemd service

Role structure:

    ansible/roles/cloudflared/
    ├── tasks/
    │   └── main.yml
    ├── templates/
    │   ├── config.yml.j2
    │   └── credentials.json.j2
    ├── handlers/
    │   └── main.yml
    └── defaults/
        └── main.yml

### Milestone 3: Configure Tunnel Ingress Rules

The cloudflared config.yml defines which hostnames route to which backend services. All HTTP traffic routes to ingress-nginx, which handles path-based routing internally.

Config template (`config.yml.j2`):

    tunnel: {{ cloudflared_tunnel_id }}
    credentials-file: /etc/cloudflared/credentials.json

    ingress:
      - hostname: argo.shrub.dev
        service: http://localhost:80
      - hostname: signoz.shrub.dev
        service: http://localhost:80
      - hostname: hey.shrub.dev
        service: http://localhost:80
      # Catch-all rule (required)
      - service: http_status:404

The `localhost:80` target works because ingress-nginx runs as a DaemonSet with hostPort, making it accessible on each node's localhost.

### Milestone 4: Deploy to Public Nodes

Create a playbook that deploys the cloudflared role to all public nodes:

    ansible/playbooks/cloudflared.yml:
    ---
    - name: Deploy Cloudflare Tunnel
      hosts: public_nodes
      become: true
      roles:
        - cloudflared

Run with:

    ansible-playbook -i ansible/hosts.ini ansible/playbooks/cloudflared.yml

### Milestone 5: Migrate DNS Records

After cloudflared is running on all nodes and connected to Cloudflare, migrate DNS from A records to CNAME records pointing to the tunnel.

For each hostname:

    cloudflared tunnel route dns homelab-ha argo.shrub.dev
    cloudflared tunnel route dns homelab-ha signoz.shrub.dev
    cloudflared tunnel route dns homelab-ha hey.shrub.dev

This creates CNAME records: `<hostname> → <tunnel-id>.cfargotunnel.com`

Important: external-dns will need to be configured to NOT manage these records, or it will overwrite them with A records. Options:

1. Add annotation to Ingress: `external-dns.alpha.kubernetes.io/exclude: "true"`
2. Or filter by hostname in external-dns config
3. Or disable external-dns for these specific hostnames

### Milestone 6: Verify Failover

Test that failover works correctly:

1. Access a service (e.g., https://argo.shrub.dev)
2. Stop cloudflared on one node: `sudo systemctl stop cloudflared`
3. Refresh the page — should still work (routed to another node)
4. Check Cloudflare dashboard for connection status
5. Restart cloudflared: `sudo systemctl start cloudflared`

### Milestone 7: Optional Hardening

After confirming tunnel works, optionally remove direct inbound access:

    # On each public node (careful - ensure tunnel is working first!)
    sudo ufw delete allow 80/tcp
    sudo ufw delete allow 443/tcp

This forces all traffic through Cloudflare, adding DDoS protection.

## Concrete Steps

All commands assume the working directory is the repository root (`~/Code/personal/homelab`).

### Step 1: Create tunnel

    cloudflared tunnel create homelab-ha

    # Expected output:
    # Tunnel credentials written to /Users/akash/.cloudflared/<uuid>.json
    # Created tunnel homelab-ha with id <uuid>

Save the UUID for later use.

### Step 2: Create Ansible role directory structure

    mkdir -p ansible/roles/cloudflared/{tasks,templates,handlers,defaults}

### Step 3: Create role files

Create `ansible/roles/cloudflared/defaults/main.yml`:

    ---
    cloudflared_tunnel_id: "{{ vault_cloudflared_tunnel_id }}"
    cloudflared_tunnel_secret: "{{ vault_cloudflared_tunnel_secret }}"
    cloudflared_account_id: "{{ vault_cloudflared_account_id }}"

    cloudflared_ingress:
      - hostname: argo.shrub.dev
        service: http://localhost:80
      - hostname: signoz.shrub.dev
        service: http://localhost:80
      - hostname: hey.shrub.dev
        service: http://localhost:80

Create `ansible/roles/cloudflared/tasks/main.yml`:

    ---
    - name: Add Cloudflare GPG key
      ansible.builtin.get_url:
        url: https://pkg.cloudflare.com/cloudflare-main.gpg
        dest: /usr/share/keyrings/cloudflare-main.gpg
        mode: '0644'

    - name: Add Cloudflare repository
      ansible.builtin.apt_repository:
        repo: "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared {{ ansible_distribution_release }} main"
        state: present
        filename: cloudflared

    - name: Install cloudflared
      ansible.builtin.apt:
        name: cloudflared
        state: present
        update_cache: true

    - name: Create cloudflared config directory
      ansible.builtin.file:
        path: /etc/cloudflared
        state: directory
        owner: root
        group: root
        mode: '0755'

    - name: Deploy tunnel credentials
      ansible.builtin.template:
        src: credentials.json.j2
        dest: /etc/cloudflared/credentials.json
        owner: root
        group: root
        mode: '0600'
      notify: Restart cloudflared

    - name: Deploy tunnel config
      ansible.builtin.template:
        src: config.yml.j2
        dest: /etc/cloudflared/config.yml
        owner: root
        group: root
        mode: '0644'
      notify: Restart cloudflared

    - name: Install cloudflared service
      ansible.builtin.command:
        cmd: cloudflared service install
        creates: /etc/systemd/system/cloudflared.service

    - name: Enable and start cloudflared
      ansible.builtin.systemd:
        name: cloudflared
        enabled: true
        state: started

Create `ansible/roles/cloudflared/handlers/main.yml`:

    ---
    - name: Restart cloudflared
      ansible.builtin.systemd:
        name: cloudflared
        state: restarted

Create `ansible/roles/cloudflared/templates/credentials.json.j2`:

    {
      "AccountTag": "{{ cloudflared_account_id }}",
      "TunnelID": "{{ cloudflared_tunnel_id }}",
      "TunnelSecret": "{{ cloudflared_tunnel_secret }}"
    }

Create `ansible/roles/cloudflared/templates/config.yml.j2`:

    tunnel: {{ cloudflared_tunnel_id }}
    credentials-file: /etc/cloudflared/credentials.json

    ingress:
    {% for rule in cloudflared_ingress %}
      - hostname: {{ rule.hostname }}
        service: {{ rule.service }}
    {% endfor %}
      - service: http_status:404

### Step 4: Add secrets to Ansible Vault

    # Extract values from credentials JSON
    cat ~/.cloudflared/<uuid>.json

    # Create or edit vault file
    ansible-vault edit ansible/group_vars/public_nodes/vault.yml

    # Add:
    vault_cloudflared_tunnel_id: "<uuid>"
    vault_cloudflared_tunnel_secret: "<secret from JSON>"
    vault_cloudflared_account_id: "<account tag from JSON>"

### Step 5: Create playbook

Create `ansible/playbooks/cloudflared.yml`:

    ---
    - name: Deploy Cloudflare Tunnel
      hosts: public_nodes
      become: true
      roles:
        - cloudflared

### Step 6: Deploy

    ansible-playbook -i ansible/hosts.ini ansible/playbooks/cloudflared.yml --vault-password-file ./vault.pass

### Step 7: Route DNS

    cloudflared tunnel route dns homelab-ha argo.shrub.dev
    cloudflared tunnel route dns homelab-ha signoz.shrub.dev
    cloudflared tunnel route dns homelab-ha hey.shrub.dev

### Step 8: Verify

    # Check tunnel status
    cloudflared tunnel info homelab-ha

    # Should show 3 connections (one per node)

    # Test service access
    curl -I https://argo.shrub.dev

    # Test failover
    ssh pam-amd1 'sudo systemctl stop cloudflared'
    curl -I https://argo.shrub.dev  # Should still work
    ssh pam-amd1 'sudo systemctl start cloudflared'

## Validation and Acceptance

Acceptance criteria:

1. `cloudflared tunnel info homelab-ha` shows 3 active connections
2. All services (argo.shrub.dev, signoz.shrub.dev, hey.shrub.dev) are accessible
3. Stopping cloudflared on any single node does not cause service outage
4. DNS records show CNAME to `<uuid>.cfargotunnel.com` instead of A records

Verification commands:

    # Check connections
    cloudflared tunnel info homelab-ha

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

## Idempotence and Recovery

The Ansible role is idempotent — running it multiple times produces the same result. The `cloudflared service install` command uses `creates:` to skip if already installed.

If a node fails:

1. Other nodes continue serving traffic automatically
2. Fix the node and restart cloudflared: `sudo systemctl start cloudflared`
3. Cloudflare automatically adds it back to the pool

To rollback to direct A records:

1. Update DNS manually or via external-dns to point to pam-amd1
2. Stop cloudflared: `ansible public_nodes -m service -a "name=cloudflared state=stopped"`
3. Optionally uninstall: `ansible public_nodes -m apt -a "name=cloudflared state=absent"`

## Artifacts and Notes

Files to be created:

    ansible/roles/cloudflared/
    ├── tasks/main.yml
    ├── templates/config.yml.j2
    ├── templates/credentials.json.j2
    ├── handlers/main.yml
    └── defaults/main.yml

    ansible/playbooks/cloudflared.yml
    ansible/group_vars/public_nodes/vault.yml (encrypted)

## Interfaces and Dependencies

External dependencies:

- Cloudflare account with shrub.dev zone
- `cloudflared` CLI authenticated (`~/.cloudflared/cert.pem`)
- Ansible with vault password for encrypted secrets

Internal dependencies:

- ingress-nginx running as DaemonSet with hostPort 80/443
- `[public_nodes]` group in `ansible/hosts.ini` containing pam-amd1, angela-amd2, toby-gcp1

The tunnel credentials JSON contains three fields that must be stored in Ansible Vault:

    AccountTag: Cloudflare account ID
    TunnelID: UUID of the tunnel
    TunnelSecret: Base64-encoded secret for authentication

---

Plan history:

- (2025-12-22) Initial plan created based on discussion of CGNAT bypass and service HA requirements.
