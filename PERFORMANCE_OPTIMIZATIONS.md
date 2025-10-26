# Ansible Performance Optimizations

## Current Bottlenecks in vpn.yml (~3-5 minutes)

1. **Sequential execution** - hosts wait for each other
2. **Fact gathering** - runs on every host (~2-5s each)
3. **apt update_cache** - can be slow on Oracle/GCP
4. **Download retries** - 3 attempts with 5s delay each
5. **Multiple plays** - Play 1 (pam-amd1), then Play 2 (all nodes)

## Proposed Optimizations

### 1. Use `strategy: free` (Biggest Win: ~50% faster)

**What:** Allows each host to run independently without waiting for others

**Before:**
```yaml
- name: Install and Configure Tailscale
  hosts:
    - vpn
    - pi_workers
    - oracle_workers
    - gcp_workers
  become: true
```

**After:**
```yaml
- name: Install and Configure Tailscale
  hosts:
    - vpn
    - pi_workers
    - oracle_workers
    - gcp_workers
  become: true
  strategy: free  # <-- Add this
```

**Impact:** ~8 hosts run in parallel instead of sequentially = 2-3 minutes saved

### 2. Disable Fact Gathering (10-20s saved)

**What:** Skip automatic fact collection if not needed

```yaml
- name: Install and Configure Tailscale
  hosts:
    - vpn
    - pi_workers
    - oracle_workers
    - gcp_workers
  become: true
  strategy: free
  gather_facts: false  # <-- Add this (only if facts aren't used)
```

**Impact:** Saves 2-5s per host × 8 hosts = 16-40s saved

### 3. Remove Unnecessary Stat Check (Optional)

**Current:**
```yaml
- name: Check if Tailscale is already installed
  ansible.builtin.stat:
    path: /usr/sbin/tailscaled
  register: tailscale_binary
```

**Why it exists:** Optimization to skip download/install if already installed

**Can we remove it?** 
- ✅ YES if Tailscale is always installed (stable environment)
- ❌ NO on first-time setups
- 🤔 MAYBE use a variable flag to toggle this check

The check itself is fast (~0.5s), but the conditional logic adds complexity.

### 4. SSH Pipelining (10-15s saved)

**What:** Reduces SSH connection overhead

**Add to ansible.cfg:**
```ini
[defaults]
pipelining = True
```

**Impact:** Fewer SSH round-trips = 10-15s saved overall

### 5. SSH ControlPersist (Connection Reuse)

**What:** Keeps SSH connections alive between tasks

**Add to ansible.cfg:**
```ini
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

**Impact:** Reuses connections = 5-10s saved

### 6. Async Downloads (for multiple hosts)

**What:** Download in parallel across hosts (already implicit with `strategy: free`)

**Current:**
```yaml
- name: Download tailscale script
  ansible.builtin.get_url:
    url: https://tailscale.com/install.sh
    dest: /tmp/tailscale.sh
    mode: "0755"
    force: true
  when: not tailscale_binary.stat.exists
  register: download_result
  until: download_result is success
  retries: 3
  delay: 5
```

**With `strategy: free`, this already runs in parallel** - no change needed!

## Quick Wins Summary

| Optimization | Time Saved | Risk | Effort |
|--------------|-----------|------|--------|
| strategy: free | 2-3 min | Low | 1 line |
| gather_facts: false | 16-40s | Low | 1 line |
| SSH pipelining | 10-15s | Low | ansible.cfg |
| ControlPersist | 5-10s | Low | ansible.cfg |
| Remove stat check | ~5s | Medium | Refactor |

**Total potential savings: 3-4 minutes → 1-1.5 minutes (50-70% faster)**

## Implementation Plan

### Phase 1: Safe Quick Wins (PR #257)
```yaml
# vpn.yml - Play 2
- name: Install and Configure Tailscale
  hosts:
    - vpn
    - pi_workers
    - oracle_workers
    - gcp_workers
  become: true
  strategy: free          # <-- Add
  gather_facts: false     # <-- Add (verify facts not used first)
```

### Phase 2: ansible.cfg optimization (PR #258)
```ini
[defaults]
pipelining = True
forks = 10

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

## Testing

```bash
# Measure before
time ansible-playbook -i hosts.ini vpn.yml

# Apply optimizations

# Measure after
time ansible-playbook -i hosts.ini vpn.yml

# Expected: 3-4min → 1-1.5min
```

## Trade-offs

**strategy: free**
- ✅ Much faster
- ❌ Harder to debug (hosts finish at different times)
- ❌ Can't rely on host order
- ✅ Perfect for independent installs like Tailscale

**gather_facts: false**
- ✅ Faster
- ❌ Can't use ansible_facts in tasks
- ✅ Fine if tasks don't need facts (check first!)

**Remove stat check**
- ✅ Slightly faster, less code
- ❌ Downloads/installs even if already installed (idempotent but slower on reruns)
- 🤔 Not recommended - the check is valuable

## CI/CD Optimization: Skip Actual Playbook Runs on PRs

**Current workflow (`.github/workflows/actions.yml`):**
1. Dry-run check (PR only) - validates syntax, shows diffs
2. Run vpn-playbook - actually applies changes

**Problem:** Step 2 is redundant on PRs since dry-run already validates!

**Optimization:**
```yaml
- name: Run vpn-playbook
  id: vpn_playbook
  if: github.event_name == 'push'  # <-- Add this: only run on push to main
  run: |
    ansible-playbook --private-key /home/runner/.ssh/id_rsa -i hosts.ini vpn.yml --vault-password-file ./vault.pass
```

**Impact:**
- PRs: Only dry-run (~30s faster, no actual changes)
- Main branch: Full execution (dry-run + actual run for safety)

**Benefit:** Faster PR feedback + no risk of applying changes during review

## Recommendation

**Do This Now:**
1. Add `strategy: free` to Play 2 (Tailscale installation)
2. Verify no facts are used, then add `gather_facts: false`
3. Add ansible.cfg with pipelining
4. **Skip actual vpn-playbook run on PRs** (only dry-run)

**Expected Result:** 
- Current: ~3-5 minutes
- After: ~1-2 minutes (main branch)
- **PR checks: ~30s** (dry-run only)
- **60-70% faster overall!**
