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

1. **Avoid ignoring meta-arguments via lifecycle (Codex P1)** — **Implemented.** The
   reserved IP now declares explicit create/delete timeouts so Terraform no longer tries to
   reconcile the provider-computed values (oracle/vcn.tf:15-31). This replaces the invalid
   `ignore_changes` workaround Codex warned about.

### PR 312 — Hotfix: pin reserved IP timeouts

1. **Empty `timeouts {}` block will not stop drift (Codex P2)** — **Implemented.** The
   follow-up change above supersedes the earlier placeholder by setting concrete timeout
   values, so the Codex guidance is now satisfied (oracle/vcn.tf:15-31).

### PR 311 — Hotfix: clean up Terraform moved blocks

1. **Restore migration from pre-for_each instance resources (Codex P1)** — **Partially
   addressed.** Terraform does not allow multiple `moved` statements to target the same
   destination, so we preserved the automatic move for the more recent friendly-name
   rollback and documented manual `terraform state mv …` commands for anyone still on the
   pre-for_each resources (`docs/ORACLE_STATE_MIGRATION.md`). This avoids destructive plans
   without breaking Terraform validation.

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
2. **Preserve earlier Terraform state migration (Codex P1)** — **Partially addressed.** See
   the manual migration steps documented in `docs/ORACLE_STATE_MIGRATION.md`; Terraform can’t
   model both historical addresses at once without failing validation, so operators must run
   the state-move commands once on extremely old deployments.

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

- All audited Codex recommendations related to code/configuration are implemented.
- Pre-for_each Oracle states require a one-time manual migration detailed in
  `docs/ORACLE_STATE_MIGRATION.md` because Terraform forbids automatically mapping multiple
  historical addresses to the same destination.
