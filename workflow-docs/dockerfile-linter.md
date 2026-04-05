# `dockerfile-linter.yml`

## Purpose

Lints `Dockerfile` using Hadolint, a Haskell-based Dockerfile linter that enforces Docker best practices, and uploads SARIF results to GitHub Advanced Security.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[dev, main]` |
| `pull_request` | branches: `[dev]` |
| `schedule` | `17 13 * * 0` (Sunday 13:17 UTC) |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~30 s |
| Concurrency | none |
| Permissions | `contents: read`, `security-events: write`, `actions: read` |

---

## Jobs

### `hadolint` — Run hadolint scanning

**Steps:**

1. `actions/checkout@v4` — checks out source
2. `hadolint/hadolint-action@f988afea3da57ee48710a9795b6bb677cc901183` — lints `./Dockerfile`; outputs `hadolint-results.sarif`; `no-fail: true` allows SARIF generation even on findings
3. `github/codeql-action/upload-sarif@v3` — uploads SARIF to GitHub code scanning

---

## Required Secrets

None.

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| All `REPOS` | Receives this file — a no-op if the repo has no `Dockerfile` |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|----------|
| `actions/checkout` | tag ref `v4` | — |
| `hadolint/hadolint-action` | `f988afea3da57ee48710a9795b6bb677cc901183` | — |
| `github/codeql-action/upload-sarif` | tag ref `v3` | — |

---

## Known Limitations / Notes

- `dependabot[bot]` actors are excluded.
- The workflow always targets `./Dockerfile` at the repo root; repos with Dockerfiles at other paths will not be linted without a local override.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
