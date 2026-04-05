# `dco-check.yml`

## Purpose

Checks that every commit in a pull request includes a `Signed-off-by:` line, enforcing Developer Certificate of Origin (DCO) compliance across all contributions.

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
| Typical duration | ~20 s |
| Concurrency | none |
| Permissions | default |

---

## Jobs

### `dco` — DCO

**Steps:**

1. `actions/checkout@v4` — full history fetch (`fetch-depth: 0`)
2. `Set up environment variables` — captures `BASE_BRANCH` and `HEAD_BRANCH` from PR context
3. `Check for DCO Sign-off` — iterates commits between head and base; fails listing non-compliant SHAs

---

## Required Secrets

None.

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| All `REPOS` | Receives this file |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|----------|
| `actions/checkout` | tag ref `v4` | — |

---

## Known Limitations / Notes

- `dependabot[bot]` actors are excluded.
- The `git log` range uses `origin/HEAD_BRANCH..origin/BASE_BRANCH`, which gives commits present in the base but absent from the head — the reverse of what a DCO check requires. The correct range is `origin/BASE_BRANCH..origin/HEAD_BRANCH`. This is a latent bug; the check may pass silently on PRs that contain unsigned commits.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
