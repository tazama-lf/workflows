# `njsscan-ci.yml`

## Purpose

Centralised reusable workflow that runs NJSScan (nodejsscan) static application security testing on Node.js source. Results are uploaded to GitHub Advanced Security as a SARIF report. Called by the [`njsscan.yml`](njsscan.md) caller stub in every consumer repo. **Not synced to consumer repos.**

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by `njsscan.yml` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~2-3 min |
| Concurrency | none |
| Permissions | `security-events: write`, `actions: read` |

---

## Jobs

### `njsscan`

**Steps:**

1. `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5` (v4) - checks out source
2. `ajinabraham/njsscan-action@d58d8b2f26322cd4c57d4a32f4773c2f2b1aba26` - runs NJSScan; `continue-on-error: true` so the job always proceeds to the SARIF upload step regardless of findings
3. `github/codeql-action/upload-sarif@5c8a8a642e79153f5d047b10ec1cba1d1cc65699` (v3) - uploads the SARIF output to GitHub Advanced Security; runs only `if: steps.njsscan.outcome == 'success'` (skipped if the scanner itself errored); `category: njsscan` distinguishes results from other SARIF sources

---

## Required Secrets

None. Uses the default `GITHUB_TOKEN` (implicit).

---

## Permissions

| Scope | Level |
|-------|-------|
| `security-events` | `write` |
| `actions` | `read` |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | `34e114876b0b11c390a56381ad16ebd13914f8d5` | v4 |
| `ajinabraham/njsscan-action` | `d58d8b2f26322cd4c57d4a32f4773c2f2b1aba26` | - |
| `github/codeql-action/upload-sarif` | `5c8a8a642e79153f5d047b10ec1cba1d1cc65699` | v3 |
