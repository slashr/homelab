# PLAN: Audit Last 7 Codex Review Outcomes

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`,
`Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.
Maintain this plan per the requirements documented in `PLANS.md`.

## Purpose / Big Picture

The user needs confidence that Codex review feedback was followed in the seven most
recent merged pull requests. After this change, anyone can open an audit report in this
repository, see every Codex inline comment for those PRs, and understand whether the
suggestion was implemented, intentionally skipped, or still outstanding. The report will
also link back to the referenced files so future contributors can confirm alignment
quickly.

## Progress

- [x] (2025-11-14 17:15Z) Created `chore/review-last-7-prs` branch and captured the audit scope in this ExecPlan.
- [x] (2025-11-14 17:25Z) Pulled PRs #308–#314 via `gh pr list` and saved each Codex review thread to `/tmp/pr<id>.json` for analysis.
- [x] (2025-11-14 17:40Z) Reviewed every Codex comment against the current files (AGENTS.md, oracle/{vcn,servers}.tf, ansible/roles/firmware_upgrade) and captured status notes for the report.
- [x] (2025-11-14 17:50Z) Authored `reports/codex-review-audit-20251114.md` covering all PRs with per-comment status and evidence.
- [x] (2025-11-14 17:55Z) Ran `pre-commit run --files PLAN.md reports/codex-review-audit-20251114.md`
      to ensure the touched files pass; full `--all-files` still fails on unrelated repo
      lint, which will be noted in the PR.
- [x] (2025-11-14 18:05Z) Replaced the invalid OCI reserved IP lifecycle hack with explicit
      create/delete timeouts and ran `terraform fmt`.
- [x] (2025-11-14 18:07Z) Added the missing legacy `moved` blocks for Oracle instances and
      ran `terraform init -backend=false` + `terraform validate` under `oracle/`.
- [x] (2025-11-14 18:09Z) Updated the audit report to mark the previously outstanding
      Codex comments as implemented.
- [x] (2025-11-14 18:45Z) Observed CI run `19373617018` failing in Terraform Oracle because
      Terraform forbids multiple `moved` blocks targeting the same destination.
- [x] (2025-11-14 18:55Z) Closed the temporary doc-only PR (#317) and spun up a fresh fix
      branch per the user's request.
- [x] (2025-11-14 19:05Z) Removed the conflicting `moved` blocks, added manual migration
      docs, refreshed the audit report, and reran targeted format/validate checks locally.
- [x] (2025-11-14 19:45Z) Ran `terraform state list` in the Oracle workspace with Terraform
      1.9.8 (after auth) to confirm no legacy `oci_core_instance.<name>` addresses remain;
      the documented `state mv` commands were not needed.

## Surprises & Discoveries

- Observation: `gh pr view --json` still lacks `reviewThreads`, so the audit had to rely on
  the GraphQL query documented in AGENTS.md; saved JSON payloads under `/tmp/pr<id>.json`
  for traceability.
- Observation: The main branch continues to include `ignore_changes = [timeouts]` for
  `oci_core_public_ip.reserved_public_ip` (oracle/vcn.tf:22-24), confirming Codex’s warning
  that this meta-argument workaround never landed.
- Observation: Repository-wide `pre-commit run --all-files` currently fails due to existing
  yamllint/markdownlint issues (outside this change); only the touched markdown files were
  linted successfully.
- Observation: Terraform 1.9 rejects configurations where two `moved` statements point to
  the same `oci_core_instance.instances["<name>"]` destination, so we must document manual
  `terraform state mv` commands for the oldest Oracle states instead of encoding both moves.

## Decision Log

- Decision: Capture the audit in `reports/codex-review-audit-20251114.md` (within a new
  `reports/` directory) so future audits can live alongside each other without overwriting
  prior plans.
  Rationale: Keeps findings versioned in-repo and easy to reference from subsequent PRs.
  Date/Author: 2025-11-14 / slashr
- Decision: Pin both create and delete timeouts on the reserved OCI public IP resource to
  10 minutes.
  Rationale: Any explicit values prevent Terraform from flagging provider-computed values;
  10 minutes aligns with typical OCI networking defaults without unduly delaying failures.
  Date/Author: 2025-11-14 / slashr
- Decision: Document manual `terraform state mv` commands for the pre-for_each Oracle
  resource addresses instead of encoding duplicate `moved` blocks that Terraform would
  reject.
  Rationale: Terraform enforces one source per destination in `moved` statements, so we can
  only automate the friendly-name rollback; the much older state format now has clear
  runbook instructions (`docs/ORACLE_STATE_MIGRATION.md`).
  Date/Author: 2025-11-14 / slashr

## Outcomes & Retrospective

- Delivered `reports/codex-review-audit-20251114.md`, which documents each Codex comment,
  the implemented fixes (OCI timeouts + friendly-name migrations), and the new manual
  runbook for the much older `oci_core_instance.<name>` states (`docs/ORACLE_STATE_MIGRATION.md`).
  Verified (2025-11-14 19:45Z) that the production Oracle state already uses the for_each
  addresses, so no manual `terraform state mv` steps were required this time.

## Context and Orientation

This repository codifies a hybrid homelab with Terraform, Ansible, and supporting
documentation. GitHub Actions enforce Codex automated reviews on every PR. Our work
focuses on documentation—no Terraform/Ansible runs are needed—so validation is limited to
verifying the report content. The seven latest merged PRs will be fetched via the GitHub
CLI (`gh`). Each PR’s review threads must be inspected to capture Codex’s inline comments.
For every comment, we will open the current workspace file referenced in the suggestion
(paths such as `ansible/playbooks/...` or `.github/workflows/...`) and verify whether the
suggestion was implemented. Evidence will be cited by file path and line numbers inside
the new report.

## Plan of Work

1. Use `gh pr list --state merged --limit 7 --sort merged_at --json ...` to capture the
   latest merged PR numbers and titles. Store them in temporary notes.
2. For each PR number, run `gh api graphql -f query='…reviewThreads…' -F n=<num>` to
   extract Codex review comments. Identify Codex threads by author login (usually
   `chatgpt-codex-connector`); capture comment text, file path, and any resolutions already
   mentioned in the thread.
3. Compare each Codex suggestion against the current code. Use `rg` or open files directly
   to confirm whether the code reflects the recommendation. Where the repository
   intentionally diverges, note the rationale (e.g., suggestion already satisfied,
   alternative implementation, or intentionally skipped).
4. Create `reports/codex-review-audit-20251114.md` summarizing, for every PR, the Codex
   comments and our current assessment (implemented, intentionally skipped with reason, or
   missing). Include direct file references with line numbers so a reader can validate
   quickly.
5. Review the report for clarity, run any required linters if the repo prescribes them
   (none expected for docs-only changes), and ensure `git status` reflects only the
   plan/report edits before opening the PR.

## Concrete Steps

1. `gh pr list --state merged --limit 7 --sort merged_at --json number,title,mergedAt,author
   --jq '...'`
2. For each PR number, run:

       gh api graphql -f query='query($n:Int!){
         repository(owner:"slashr",name:"homelab"){
           pullRequest(number:$n){
             reviewThreads(first:100){
               nodes{
                 isResolved
                 comments(first:20){
                   nodes{
                     author{login}
                     body
                     path
                     originalLine
                     line
                     diffHunk
                   }
                 }
               }
             }
           }
         }
       }' -F n=<num>
3. Inspect referenced files via `rg`/`sed`/`bat` as needed to compare suggestions vs. code.
4. Write findings into `reports/codex-review-audit-20251114.md`.
5. `git status`, `git diff`, and, if required, `pre-commit run --all-files`.

## Validation and Acceptance

Acceptance is met when `reports/codex-review-audit-20251114.md` exists, lists each of the
seven latest merged PRs, and for every Codex comment records (a) the recommendation,
(b) whether the current code implements it, and (c) file references proving the
assessment. Open the report to confirm it is readable and self-contained. No automated
tests are expected, but `pre-commit run --all-files` should succeed if run.

## Idempotence and Recovery

The audit process is read-only against GitHub and the workspace. Re-running the GitHub CLI
commands is safe. If a mistake is found in the report, edit the markdown and re-run
validation. The report can be regenerated at any time by repeating the steps with the same
PR list; only human time is required.

## Artifacts and Notes

- `reports/codex-review-audit-20251114.md` — primary deliverable containing per-PR findings.

## Interfaces and Dependencies

- GitHub CLI (`gh`) with repository access to list merged PRs and fetch review threads.
  Network access approval will be required due to the restricted environment.
- Local workspace files for verifying whether Codex’s suggestions were implemented.

---

Plan history:

- (2025-11-14 17:15Z) Created the ExecPlan for the Codex audit task.
