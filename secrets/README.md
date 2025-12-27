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

### 4. Create and encrypt kube secrets

```bash
# Copy the example file
cp secrets/kube.yaml.example secrets/kube.yaml

# Edit with your actual values (keep base64-encoded, Terraform decodes them)
# Get values from your cluster:
kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}'
kubectl config view --raw -o jsonpath='{.users[0].user.client-key-data}'
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'

# Encrypt in place
sops -e -i secrets/kube.yaml

# Commit the encrypted file
git add secrets/kube.yaml
git commit -m "Add encrypted kube secrets"
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
4. Re-encrypt all secrets: `sops updatekeys secrets/kube.yaml`
5. Update `SOPS_AGE_SECRET_KEY` in GitHub Secrets

## Security Notes

* **Never commit** `secrets/*.yaml` (unencrypted) - gitignore protects this
* **Never commit** your age private key (`keys.txt`)
* The encrypted file (`secrets/kube.yaml`) is safe to commit
* Only values are encrypted, keys remain visible (this is by design)
