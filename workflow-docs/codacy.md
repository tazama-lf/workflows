# `codacy.yml`

## Purpose

Performs a Codacy security scan of the codebase and uploads results in SARIF format to GitHub Advanced Security (code scanning dashboard).

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[dev, main]` |
| `pull_request` | branches: `[dev, main]` |
| `schedule` | `17 0 * * 4` (Thursday 00:17 UTC) |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~2–3 min |
| Concurrency | none |
| Permissions | `contents: read`, `security-events: write`, `actions: read` |

---

## Jobs

### `codacy-security-scan` — Codacy Security Scan

**Steps:**

1. `actions/checkout@v4` — checks out source
2. `codacy/codacy-analysis-cli-action@562ee3e92b8e92df8b67e0a5ff8aa8e261919c08` — runs Codacy CLI; outputs `results.sarif`; `max-allowed-issues: 2147483647` defers PR rejection to GitHub
3. `github/codeql-action/upload-sarif@v3` — uploads `results.sarif` to GitHub code scanning

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|-------|
| `CODACY_PROJECT_TOKEN` | repo | Authenticate with the Codacy project |

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| All `REPOS` | Receives this file |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|----------|
| `codacy/codacy-analysis-cli-action` | `562ee3e92b8e92df8b67e0a5ff8aa8e261919c08` | v4.4.7 |
| `github/codeql-action/upload-sarif` | tag ref `v3` | — |

---

## Known Limitations / Notes

- Codacy CLI v4.4.7 is the latest available release. A known Java charset decoder bug (`MalformedInputException: Input length = 2`) causes the workflow to crash when checkov outputs code snippets from modified multi-line YAML files. Mitigated in this repo by `.checkov.yaml` (skips `github_actions` framework). Individual synced repos that modify complex YAML workflows may need the same `.checkov.yaml`.
- `dependabot[bot]` actors are excluded.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
