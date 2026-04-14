# `gpg-verify.yml`

## Purpose

Verifies that every commit in a pull request has a valid GPG signature using the GitHub REST API, ensuring that only verified commits can be merged.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `pull_request` | all types |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~20–30 s |
| Concurrency | none |
| Permissions | default |

---

## Jobs

### `gpg-verify` - GPG Verify

**Steps:**

1. `actions/checkout@v4` - full history fetch (`fetch-depth: 0`)
2. `Set up environment variables` - captures `PR_HEAD_REF`, `PR_BASE_REF`, `GITHUB_TOKEN`, `GITHUB_REPOSITORY`
3. `Check GPG verification status` - iterates commits via `git log origin/${PR_BASE_REF}..origin/${PR_HEAD_REF}`; queries `/repos/:repo/commits/:sha` for each and checks `.commit.verification.verified`; fails if any commit is unverified

---

## Required Secrets

None (uses auto-provided `GITHUB_TOKEN`).

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| All `REPOS` | Receives this file |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|----------|
| `actions/checkout` | tag ref `v4` | - |

---

## Known Limitations / Notes

- `dependabot[bot]`, `dependabot-preview[bot]`, and `github-actions[bot]` actors are excluded - these automated actors do not have GPG keys and will never produce signed commits.
- An empty commit range (e.g. no new commits on the head branch) is handled gracefully - the step exits 0 without failing.
- GPG verification is checked via the GitHub commit API (`.commit.verification.verified`), which uses the committer's GitHub-linked public key. Local GPG keyrings on the runner are not required.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
