# `njsscan.yml`

## Purpose

Runs the njsscan (nodejsscan) static security scanner against the Node.js codebase to identify insecure code patterns, and uploads results as SARIF to GitHub Advanced Security.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[dev, main]` |
| `pull_request` | branches: `[dev, main]` |
| `schedule` | `17 17 * * 1` (Monday 17:17 UTC) |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~1–2 min |
| Concurrency | none |
| Permissions | `contents: read`, `security-events: write`, `actions: read` |

---

## Jobs

### `njsscan` — njsscan code scanning

**Steps:**

1. `actions/checkout@v4` — checks out source
2. `ajinabraham/njsscan-action@d58d8b2f26322cd35a9efb8003baac517f226d81` — scans `.`; outputs `results.sarif`; `|| true` ensures SARIF is always generated even when issues are found
3. `github/codeql-action/upload-sarif@v3` — uploads `results.sarif`

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
| `ajinabraham/njsscan-action` | `d58d8b2f26322cd35a9efb8003baac517f226d81` | — |
| `github/codeql-action/upload-sarif` | tag ref `v3` | — |

---

## Known Limitations / Notes

- `dependabot[bot]` actors are excluded.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
