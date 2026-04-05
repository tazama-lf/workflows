# `branch-target-check.yml`

## Purpose

Enforces the feature-branch → dev → main development workflow by failing any PR to `main` that does not originate from `dev` or a `release/v<N>.*` branch, saving developers from confusing branch-protection errors.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `pull_request` | branches: `[main]` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~15 s |
| Concurrency | none |
| Permissions | `contents: read` |

---

## Jobs

### `check-source-branch` — verify PR source branch

**Steps:**

1. `Verify PR source branch is dev or release/v<N>.*` — shell check; exits `1` with actionable message (including `gh pr edit --base dev` hint) if source branch is not `dev` or `release/v[0-9]*`

---

## Required Secrets

None.

---

## Sync Distribution

| Group | Behaviour |
|-------|-----------|
| All `REPOS` | Receives this file |

---

## Dependencies (pinned actions)

None — single run step only.

---

## Known Limitations / Notes

- `dependabot[bot]` and `dependabot-preview[bot]` actors are excluded from the check.
- Only guards `main` as target; no equivalent check for PRs to `dev` (any source branch is permitted).
- Source branch value is passed via `env:` rather than inline `${{ github.head_ref }}` to prevent header injection.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
