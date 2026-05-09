# `codacy-ci.yml`

## Purpose

Reusable Codacy Security Scan workflow. Contains all scan logic for Tazama consumer repos. Called by the [`codacy.yml`](codacy.md) caller stub which is synced to all consumer repos.

This file is **not synced** to consumer repos - it stays in `tazama-lf/workflows` and is referenced by the stub at runtime via `uses: tazama-lf/workflows/.github/workflows/codacy-ci.yml@dev`.

Dockerized tools (e.g. Checkov) are disabled via `run-docker-tools: 'false'`. They are not applicable to TypeScript/Node.js repos and were previously triggering spurious Checkov runs despite `.codacy.yml` exclusions. ESLint and Semgrep continue to run natively and are controlled via `.codacy.yml`. See [#115](https://github.com/tazama-lf/workflows/issues/115).

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by `codacy.yml` stub in consumer repos |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~2-3 min |
| Concurrency | none |
| Permissions | `contents: read`, `security-events: write`, `actions: read` |

---

## Jobs

### `codacy-security-scan` - Codacy Security Scan

**Condition:** `github.actor != 'dependabot[bot]' && github.actor != 'dependabot-preview[bot]'`

**Steps:**

1. `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5` (v4) - checks out source
2. `codacy/codacy-analysis-cli-action@562ee3e92b8e92df8b67e0a5ff8aa8e261919c08` (v4.4.7) - runs Codacy CLI with `run-docker-tools: 'false'`; outputs `results.sarif`; `max-allowed-issues: 2147483647` defers PR rejection to GitHub
3. Merge SARIF runs - inline `jq` step that merges all SARIF runs from `results.sarif` into a single run before upload; required because the Codacy CLI emits one run per engine and `upload-sarif` rejects uploads with more than one run per category (enforced from 2025-07-21) - fixes [#98](https://github.com/tazama-lf/workflows/issues/98)
4. `github/codeql-action/upload-sarif@5c8a8a642e79153f5d047b10ec1cba1d1cc65699` (v3) - uploads the merged `results.sarif` to GitHub code scanning with `category: codacy`

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|---------|
| `CODACY_PROJECT_TOKEN` | repo | Authenticate with the Codacy project |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|-------------|
| `actions/checkout` | `34e114876b0b11c390a56381ad16ebd13914f8d5` | v4 |
| `codacy/codacy-analysis-cli-action` | `562ee3e92b8e92df8b67e0a5ff8aa8e261919c08` | v4.4.7 |
| `github/codeql-action/upload-sarif` | `5c8a8a642e79153f5d047b10ec1cba1d1cc65699` | v3 |

---

## Known Limitations / Notes

- The Codacy CLI emits one SARIF run per engine. A jq step merges all runs into a single run before upload to satisfy the `upload-sarif` single-run-per-category requirement (enforced from 2025-07-21). See [#98](https://github.com/tazama-lf/workflows/issues/98).
- `dependabot[bot]` actors are excluded via the job condition.
- When `project-token` is supplied, the Codacy cloud platform config takes precedence over the local `.codacy.yml` engine settings. The `run-docker-tools: 'false'` input bypasses this for all Docker-pulled tools regardless of cloud config.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(logic centralised here; all repos reference via stub)_ |
