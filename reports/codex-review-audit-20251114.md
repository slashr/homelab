# Codex Review Audit — 2025-11-14

## Scope & Method

I audited the seven most recent merged pull requests (PRs #308–#314) to confirm whether
every Codex review comment was addressed. For each PR I captured the review threads via
`gh api graphql … reviewThreads`, then compared the suggested changes against the current
`main` branch. Status labels below indicate whether the recommendation matches the final
code (`Implemented`), remains unresolved (`Not implemented`), or was superseded (`No longer
needed`). File references use `path:line`.

## Findings by Pull Request

### PR 314 — TASK-000: Document Codex review protocol [AXP]

1. **Clarify when to ping `@codex review again` (Codex P2)** — **Implemented.** Step 2 in
   the “Handling feedback without confusion” section now tells agents to summarize the fix
   and *hold* the `@codex review again` mention until Step 5 (AGENTS.md:105-109). This
   aligns with the Codex request to avoid per-comment pings.
2. **Resolve conflicting guidance on final pings (Codex P2)** — **Implemented.** The
   earlier workflow section under Step 6 now states to leave a single final note ending
   with `@codex review again` after all threads are handled (AGENTS.md:38-50), matching the
   new protocol.
3. **Fix jq reaction query quoting (Codex P1)** — **Implemented.** The command now embeds
   the filter without escaped quotes, e.g. `select(.content=="EYES" or .content=="THUMBS_UP")`
   (AGENTS.md:95).
4. **Remove escaped owner/name strings in GraphQL example (Codex P2)** — **Implemented.**
   The sample command now shows `owner:"slashr",name:"homelab"` so it can be copy/pasted
   directly (AGENTS.md:98).

### PR 313 — Hotfix: ignore OCI IP timeouts

1. **Avoid ignoring meta-arguments via lifecycle (Codex P1)** — **Not implemented.** Codex
   warned that `ignore_changes = [timeouts]` is invalid because `timeouts` is a
   meta-argument. The current code still sets `ignore_changes` inside the lifecycle block
   for `oci_core_public_ip.reserved_public_ip` (oracle/vcn.tf:22-24), so the plan will
   continue to fail validation and the drift persists.

### PR 312 — Hotfix: pin reserved IP timeouts

1. **Empty `timeouts {}` block will not stop drift (Codex P2)** — **Implemented (but
   superseded by PR 313 feedback).** The code no longer uses an empty block; instead it
   added the `ignore_changes = [timeouts]` entry discussed above (oracle/vcn.tf:22-24).
   Codex later pointed out that this approach is invalid (see PR 313), so additional work
   is still required even though the original P2 request was followed.

### PR 311 — Hotfix: clean up Terraform moved blocks

1. **Restore migration from pre-for_each instance resources (Codex P1)** — **Not
   implemented.** There are no `moved` statements mapping the legacy
   `oci_core_instance.amd1`/`amd2`/`arm1`/`arm2` resources into the
   `oci_core_instance.instances` map; searching for `oci_core_instance.amd1` returns no
   matches anywhere in the repo. As a result, environments that never applied the original
   for_each refactor would still destroy/recreate all four Oracle instances if they ran
   the latest code.

### PR 310 — Revert “TASK-021: Standardize Oracle server names [AXP]”

1. **Add inverse moved blocks when reverting friendly names (Codex P0)** — **Implemented.**
   The file contains four `moved` blocks translating the `instances["pam-*"]` addresses
   back to the canonical keys (oracle/servers.tf:38-57), preventing unnecessary destroys.
2. **Deduplicate moved targets (Codex P1)** — **Implemented.** Only one moved block now
   targets each canonical address, so Terraform will no longer error with duplicate `to`
   destinations.

### PR 309 — TASK-021: Standardize Oracle server names [AXP]

1. **Deduplicate moved blocks for renamed instances (Codex P1)** — **Implemented.** The
   legacy moves were removed, leaving one destination per key (oracle/servers.tf:38-57).
2. **Preserve earlier Terraform state migration (Codex P1)** — **Not implemented.** The
   repo still lacks `moved` statements for the original `oci_core_instance.<name>`
   resources (see PR 311 finding). Any environment that never applied the for_each
   transition would still face destructive recreations.

### PR 308 — TASK-030: Fix Raspberry Pi firmware package set [AXP]

1. **Dropping `libraspberrypi-bin` without guarding `vcgencmd` (multiple Codex P1s)** —
   **Implemented.** The firmware role now records whether `/usr/bin/vcgencmd` exists and
   guards every `vcgencmd` invocation with `when: firmware_vcgencmd_stat.stat.exists |
   default(false)`, emitting guidance when the binary is missing
   (ansible/roles/firmware_upgrade/tasks/main.yml:19-107). Hosts without the package fall
   back to `rpi-eeprom-update` output instead of failing.
2. **Ensure the vcgencmd guard uses a boolean (Codex P1)** — **Implemented.** The `when`
   clauses reference the boolean value returned from `stat` directly, removing the previous
   string-based fact (same file/lines as above).

## Outstanding Gaps

- **OCI reserved public IP timeouts (PR 313)** — Replace `ignore_changes = [timeouts]`
  with explicit `timeouts` values or another supported approach so plans stop failing.
- **Oracle instance state migration (PRs 309 & 311)** — Reintroduce the `moved` blocks that
  map the original `oci_core_instance.<name>` resources into
  `oci_core_instance.instances["<name>"]` before the friendly-name logic. Without them,
  older environments would destroy key infrastructure on their next apply.

No other Codex recommendations from the audited PR set remain outstanding.
