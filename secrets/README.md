# SOPS Encrypted Secrets

This directory contains SOPS-encrypted secrets for the homelab infrastructure.

## Setup (One-time)

### 1. Generate an age key pair

```bash
# Install age
brew install age  # macOS
# or: apt install age  # Ubuntu

# Generate key pair
age-keygen -o ~/.config/sops/age/keys.txt

# This outputs your public key, e.g.:
# Public key: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 2. Update .sops.yaml

Replace `AGE_PUBLIC_KEY_HERE` in `.sops.yaml` with your public key.

### 3. Add private key to GitHub Secrets

1. Go to repo Settings → Secrets → Actions
2. Create `SOPS_AGE_SECRET_KEY` with the contents of `~/.config/sops/age/keys.txt`
   (includes both the comment and the private key line)

### 4. Create and encrypt secrets

#### Kubernetes secrets (`kube.yaml`)

```bash
cp secrets/kube.yaml.example secrets/kube.yaml
# Edit with base64-encoded values from your cluster:
#   kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}'
#   kubectl config view --raw -o jsonpath='{.users[0].user.client-key-data}'
#   kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'
sops -e -i secrets/kube.yaml
```

#### Terraform secrets (`terraform.yaml`)

```bash
cp secrets/terraform.yaml.example secrets/terraform.yaml
# Edit with actual secret values:
#   - api_token: Terraform Cloud API token
#   - gcp_credentials: GCP service account JSON
#   - oci_private_key: OCI API private key
#   - cloudflare_api_token: Cloudflare API token
#   - tailscale_oauth_client_secret: Tailscale OAuth secret
sops -e -i secrets/terraform.yaml
```

#### Non-secret config (`*.tfvars`)

Non-sensitive identifiers are stored in committed tfvars files:

- `oracle/terraform.tfvars` - OCI identifiers (user_ocid, tenancy_ocid, compartment_id, fingerprint, ssh_authorized_keys)
- `kubernetes/terraform.tfvars` - Tailscale OAuth client ID

Commit the encrypted files:

```bash
git add secrets/kube.yaml secrets/terraform.yaml
git commit -m "Add encrypted secrets"
```

## Usage

### Decrypt and view

```bash
sops -d secrets/kube.yaml
```

### Edit (decrypts, opens editor, re-encrypts on save)

```bash
sops secrets/kube.yaml
```

### Extract single value

```bash
sops -d --extract '["kube_client_cert"]' secrets/kube.yaml
```

## Rotating the age key

1. Generate new key pair
2. Decrypt all secrets with old key
3. Update `.sops.yaml` with new public key
4. Re-encrypt all secrets:
   ```bash
   sops updatekeys secrets/kube.yaml
   sops updatekeys secrets/terraform.yaml
   ```
5. Update `SOPS_AGE_SECRET_KEY` in GitHub Secrets

## Security Notes

* **Never commit** `secrets/*.yaml` (unencrypted) - gitignore protects this
* **Never commit** your age private key (`keys.txt`)
* The encrypted file (`secrets/kube.yaml`) is safe to commit
* Only values are encrypted, keys remain visible (this is by design)
