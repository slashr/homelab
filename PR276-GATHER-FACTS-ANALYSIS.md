# PR #276: Add `gather_facts: false` to Security Playbook

## Overview

This PR adds `gather_facts: false` to all plays in
`ansible/playbooks/security.yml` to optimize performance by skipping
unnecessary fact collection.

## Problem Statement

Ansible's default behavior is to gather system facts (via the `setup` module)
at the start of every playbook execution. This takes approximately 2-5 seconds
per host, which adds up when running across multiple nodes.

**Current behavior:**

```bash
TASK [Gathering Facts] ************************************************** 4.23s
TASK [fail2ban : Install fail2ban] ************************************* 8.45s
TASK [firewall : Install UFW] ****************************************** 2.31s
```

The security playbook targets 5 public cloud nodes, meaning we're spending
~20-25 seconds gathering facts that are never used.

## Solution

Add `gather_facts: false` to each play in `security.yml` since the `fail2ban` and `firewall` roles do not use any Ansible facts.

## Technical Analysis

### What `gather_facts` Does

When `gather_facts: true` (default), Ansible:

1. SSH into each host
2. Runs Python code to inspect the system
3. Collects ~100+ variables (OS info, network, hardware, filesystems)
4. Stores these as Ansible facts available to all tasks

**Example facts collected:**

- `ansible_distribution` (e.g., "Ubuntu")
- `ansible_hostname` (e.g., "toby-gcp1")
- `ansible_default_ipv4.address` (e.g., "34.28.187.2")
- `ansible_memory_mb`, `ansible_processor_count`, etc.

### Why These Roles Don't Need Facts

#### `fail2ban` Role Analysis

File: `ansible/roles/fail2ban/tasks/main.yml`

```yaml
- name: Install fail2ban
  ansible.builtin.apt:
    name: fail2ban
    state: present
```

✅ **No variables used** - hard-coded package name

```yaml
- name: Create fail2ban jail.local configuration
  ansible.builtin.template:
    src: jail.local.j2
    dest: /etc/fail2ban/jail.local
```

✅ **Template uses group_vars only** - no Ansible facts referenced

**Verdict:** fail2ban role is **fact-independent**

#### `firewall` Role Analysis

File: `ansible/roles/firewall/tasks/main.yml`

```yaml
- name: Allow SSH with rate limiting (22/tcp)
  community.general.ufw:
    rule: limit
    port: '22'
    proto: tcp
```

✅ **Hard-coded values** - no variables

```yaml
- name: Check if this is the VPN gateway (pam-amd1)
  ansible.builtin.set_fact:
    is_vpn_gateway: "{{ inventory_hostname == 'pam-amd1' }}"
```

✅ **Uses `inventory_hostname`** - always available without gathering facts

**Verdict:** firewall role is **fact-independent**

### Variables Always Available Without Facts

These variables are **always present** regardless of `gather_facts`:

- `inventory_hostname` - from inventory file
- `ansible_host` - from inventory file
- `ansible_user` - from inventory file
- `ansible_python_interpreter` - from inventory file
- `ansible_check_mode` - Ansible magic variable
- `ansible_run_tags` - Ansible magic variable
- Group variables from `group_vars/`
- Host variables from `host_vars/`

### Why Other Playbooks Keep Facts Enabled

#### ❌ `pis.yml` - REQUIRES facts

```yaml
roles:
  - role: ../roles/common  # Creates MOTD with ansible_hostname, ansible_default_ipv4
  - role: ../roles/network # Uses ansible_check_mode
```

The `common` role's MOTD task would **fail** without facts:

```yaml
║  {{ ansible_hostname }}              # ← UNDEFINED without gather_facts
║  IP: {{ ansible_default_ipv4.address }}  # ← UNDEFINED without gather_facts
```

#### ❌ `vpn.yml` - Could optimize but kept default

Currently defaults to `gather_facts: true`, but tasks don't actually use facts. Could be optimized in a future PR.

#### ✅ `security.yml` - Safe to disable

Only uses `fail2ban` and `firewall` roles which are fact-independent.

## Performance Impact

### Time Savings

**Before (with gather_facts: true):**

- Gathering facts: ~4-5 seconds per host
- 5 hosts in security.yml
- **Total overhead: ~20-25 seconds**

**After (with gather_facts: false):**

- Gathering facts: **SKIPPED**
- **Total time saved: ~20-25 seconds per run**

### CI/CD Impact

- GitHub Actions workflow runs this playbook on every push to `main`
- Faster execution = reduced CI time
- Reduced GitHub Actions usage = lower costs

### Maintenance Consideration

**If future roles added to `security.yml` need facts:**

1. Add `gather_facts: true` back to that specific play
2. OR use selective gathering:

   ```yaml
   tasks:
     - name: Gather minimal facts
       ansible.builtin.setup:
         gather_subset:
           - '!all'
           - 'network'  # Only gather network facts
   ```

## Implementation Details

### Changes Made

Modified `ansible/playbooks/security.yml`:

- Added `gather_facts: false` to all 5 plays (lines 20, 28, 36, 44, 52)
- Added header comment explaining the optimization (lines 12-16)
- No changes to roles - they already don't use facts

### Testing Strategy

1. **Static verification** ✅
   - Confirmed fail2ban role uses no Ansible facts
   - Confirmed firewall role uses only `inventory_hostname`
   - Verified no linting errors

2. **Dry-run test** (recommended before merge)

   ```bash
   ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml --check --diff
   ```

3. **Live test on one node** (recommended)

   ```bash
   ansible-playbook -i ansible/hosts.ini ansible/playbooks/security.yml --limit toby-gcp1
   ```

### Rollback Plan

If any issues arise:

```bash
git revert <commit-hash>
```

Or simply remove `gather_facts: false` lines (non-breaking change)

## Risk Assessment

**Risk Level:** ⚠️ LOW

### Why Low Risk?

1. ✅ Both roles independently verified to not use facts
2. ✅ Change is non-destructive (only skips data collection)
3. ✅ Easy rollback (just re-enable gathering)
4. ✅ No changes to actual role logic
5. ✅ Fails safely (if role tried to use undefined fact, error is immediate and clear)

### Potential Issues

**Scenario:** Future developer adds task to security playbook that needs facts

**Symptom:**

```text
fatal: [toby-gcp1]: FAILED! =>
  msg: 'ansible_hostname' is undefined
```

**Solution:** Re-enable `gather_facts: true` for that play or use
selective gathering

## Logic & Reasoning Summary

### Decision Tree Used

```text
Does security.yml use any Ansible facts?
  ├─ Yes → Keep gather_facts: true (or use selective gathering)
  └─ No → Add gather_facts: false
       ├─ Check fail2ban role → No facts used ✓
       ├─ Check firewall role → No facts used ✓
       └─ Safe to proceed ✓
```

### Key Insights

1. **Performance vs. Safety Trade-off**
   - Gathering facts is "safe" but wasteful if unused
   - Disabling saves time but requires verification
   - **Verdict:** Safe to disable when verified unused

2. **Role Independence**
   - Well-designed roles should minimize fact dependencies
   - Using inventory variables > Ansible facts (when possible)
   - Makes roles more portable and faster

3. **Selective Application**
   - Don't blanket-apply to all playbooks
   - Analyze each playbook individually
   - Security playbook is ideal candidate (simple, fact-independent)

## References

- Ansible setup module:
  <https://docs.ansible.com/ansible/latest/collections/ansible/builtin/setup_module.html>
- Ansible facts gathering:
  <https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#fact-gathering>
- Performance tuning:
  <https://docs.ansible.com/ansible/latest/reference_appendices/config.html#gathering>

## Related Work

- PR #16: Ansible performance optimization (planned)
- PR #17: ansible.cfg SSH optimizations (planned)
- `ansible.cfg` already created with pipelining and ControlMaster
- `strategy: free` already added to vpn.yml for parallel execution

---

**Author's Note:** This optimization follows the principle of "pay for what
you use." Since the security playbook doesn't use gathered facts, there's no
reason to spend time collecting them. This same analysis should be applied to
other playbooks in future optimization work.
