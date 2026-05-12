# `dockerfile-linter-ci.yml`

## Purpose

Centralised reusable workflow that runs Hadolint Dockerfile linting and uploads the results to GitHub Advanced Security as a SARIF report. Called by the [`dockerfile-linter.yml`](dockerfile-linter.md) caller stub in every consumer repo. **Not synced to consumer repos.**

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by `dockerfile-linter.yml` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | < 1 min |
| Concurrency | none |
| Permissions | `security-events: write`, `actions: read`, `contents: read` |

---

## Jobs

### `hadolint`

**Steps:**

1. `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5` (v4) - checks out source
2. `hadolint/hadolint-action@f988afea3767b4b7d0f69ca498abdcba8a3b79d0` - runs Hadolint; output format `sarif`; guarded by `if: hashFiles('Dockerfile') != ''` so it is skipped cleanly in repos without a Dockerfile
3. `github/codeql-action/upload-sarif@5c8a8a642e79153f5d047b10ec1cba1d1cc65699` (v3) - uploads Hadolint SARIF results; `wait-for-processing: true`; guarded by `if: hashFiles('Dockerfile') != ''`

---

## Required Secrets

None. Uses the default `GITHUB_TOKEN` (implicit).

---

## Permissions

| Scope | Level |
|-------|-------|
| `security-events` | `write` |
| `actions` | `read` |
| `contents` | `read` |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | `34e114876b0b11c390a56381ad16ebd13914f8d5` | v4 |
| `hadolint/hadolint-action` | `f988afea3767b4b7d0f69ca498abdcba8a3b79d0` | - |
| `github/codeql-action/upload-sarif` | `5c8a8a642e79153f5d047b10ec1cba1d1cc65699` | v3 |

---

## Known Limitations / Notes

- Both the lint and upload steps are guarded by `hashFiles('Dockerfile') != ''` and are skipped cleanly in repos that have no Dockerfile.
