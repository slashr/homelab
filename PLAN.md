# PLAN: Document Codex Review Expectations (Nov 2025)

## Objective

Add a “Codex Review Protocol” section to `AGENTS.md` so every agent knows how automated Codex reviews behave (👀/👍
signals, inline replies, re-review triggers, and CLI verification commands).

## Steps

1. Summarize the Codex workflow (auto reviews, emoji status, thumbs-up merge gate) to set the context.
2. Capture the operational guardrails learned from the last four PRs: always reply inline, only request re-review
   after addressing every thread, resolve each thread, and validate Codex suggestions before implementation.
3. Document the exact `gh` CLI/GraphQL commands required to monitor reviewer state (`gh pr view … --comments`, `--json reviews`, reviewThreads query, timeline comments).
4. Re-read the new section to ensure it references all four failure modes (unresolved P0/P1, duplicate review
   requests, contradictory guidance, missing resolution checks) and that instructions are explicit.

## Validation

- `rg "Codex Review Protocol" AGENTS.md` returns the new heading.
- `gh api graphql … reviewThreads` commands described in the doc match working examples tested during this change.
