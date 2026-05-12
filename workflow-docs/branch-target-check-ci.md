# `branch-target-check-ci.yml`

## Purpose

Centralised reusable workflow that enforces the feature-branch -> dev -> main development workflow. Fails any PR to `main` that does not originate from `dev` or a `release/v<N>.*` branch. Called by the [`branch-target-check.yml`](branch-target-check.md) caller stub in every consumer repo. **Not synced to consumer repos.**

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by `branch-target-check.yml` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | < 15 s |
| Concurrency | none |
| Permissions | `contents: read` (default) |

---

## Jobs

### `check-source-branch`

**Skip condition:** actor is `dependabot[bot]` or `dependabot-preview[bot]`

**Steps:**

1. `Verify PR source branch is dev or release/v<N>.*` - shell-only check (no external actions); `SOURCE` is set via `env:` from `${{ github.head_ref }}` to prevent header injection; allows `dev` or branches matching `release/v[0-9]*`; fails with actionable message including `gh pr edit --base dev` hint if the source branch does not match

---

## Required Secrets

None. No external API calls; pure shell logic only.

---

## Permissions

| Scope | Level |
|-------|-------|
| `contents` | `read` |

---

## Dependencies (pinned actions)

None - single shell step only, no pinned actions.
