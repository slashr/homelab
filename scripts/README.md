# Scripts

This directory contains utility scripts for managing the homelab infrastructure.

## Available Scripts

### health-check.sh

A comprehensive health check script that monitors the homelab infrastructure.

**Features:**
- K3S cluster connectivity check
- Node status verification
- Critical pod health monitoring
- ArgoCD application status
- Tailscale connectivity check
- System resource monitoring (disk, memory)

**Usage:**
```bash
# Run health check
./scripts/health-check.sh

# Run with verbose output
bash -x ./scripts/health-check.sh
```

**Requirements:**
- `kubectl` configured to access the K3S cluster
- `tailscale` CLI (optional)
- `jq` for JSON parsing (optional)

**Exit Codes:**
- `0`: All checks passed
- `1`: One or more checks failed

## Adding New Scripts

When adding new scripts to this directory:

1. Make them executable: `chmod +x script-name.sh`
2. Add proper error handling with `set -euo pipefail`
3. Include usage documentation in the script header
4. Update this README with script description and usage
5. Test the script thoroughly before committing

## Integration with CI/CD

These scripts can be integrated into the GitHub Actions workflow for automated monitoring and alerting.
