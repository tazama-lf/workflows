# `dco-check-ci.yml`

## Purpose

Centralised reusable workflow that verifies every commit in a pull request is DCO-signed (`Signed-off-by: Name <email>` trailer). Called by the [`dco-check.yml`](dco-check.md) caller stub in every consumer repo. **Not synced to consumer repos.**

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by `dco-check.yml` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | < 30 s |
| Concurrency | none |
| Permissions | `contents: read` (default) |

---

## Jobs

### `dco`

**Skip condition:** actor is `dependabot[bot]`, `dependabot-preview[bot]`, or `github-actions[bot]`

**Steps:**

1. `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5` (v4) - full history checkout (`fetch-depth: 0`) so all commits in the PR range are available
2. `DCO check` - iterates `$BASE_SHA..$HEAD_SHA` (the fixed PR range set via `env:`); for each commit, checks for `Signed-off-by:` in the message; fails with per-commit error messages listing unsigned commits; exits 0 if all commits are signed

**Note:** uses the explicit `$BASE_SHA..$HEAD_SHA` git range rather than `origin/HEAD` to avoid a latent bug where `origin/HEAD` might not reflect the actual PR base branch.

---

## Required Secrets

None. Uses default `GITHUB_TOKEN` (implicit).

---

## Permissions

| Scope | Level |
|-------|-------|
| `contents` | `read` |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | `34e114876b0b11c390a56381ad16ebd13914f8d5` | v4 |
