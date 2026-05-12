# `gpg-verify-ci.yml`

## Purpose

Centralised reusable workflow that verifies every commit in a pull request is GPG-signed and the signature is verified by GitHub. Called by the [`gpg-verify.yml`](gpg-verify.md) caller stub in every consumer repo. **Not synced to consumer repos.**

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by `gpg-verify.yml` |

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

### `gpg-verify`

**Skip condition:** actor is `dependabot[bot]`, `dependabot-preview[bot]`, or `github-actions[bot]`

**Steps:**

1. `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5` (v4) - full history checkout (`fetch-depth: 0`)
2. `Verify GPG signatures` - iterates over the `$PR_BASE_SHA..$PR_HEAD_SHA` commit range (set via `env:` to prevent injection); for each commit calls the GitHub API (`/repos/$GITHUB_REPOSITORY/commits/$commit`) via `curl` and checks `.commit.verification.verified`; collects all unverified commits; fails with a list of unsigned SHAs if any are found; handles empty commit ranges gracefully

---

## Required Secrets

None. Uses the default `GITHUB_TOKEN` (implicit) for GitHub API calls.

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
