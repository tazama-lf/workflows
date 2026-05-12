# `codeql-ci.yml`

## Purpose

Centralised reusable workflow that runs CodeQL static analysis on JavaScript/TypeScript source. Results are uploaded to GitHub Advanced Security and appear in the Security tab. Called by the [`codeql.yml`](codeql.md) caller stub in every consumer repo. **Not synced to consumer repos.**

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by `codeql.yml` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~3-5 min |
| Concurrency | none |
| Permissions | `contents: read`, `security-events: write`, `actions: read` |

---

## Jobs

### `analyze`

**Skip condition:** actor is `dependabot[bot]` or `dependabot-preview[bot]`

**Matrix:** `language: ['javascript']`

**Steps:**

1. `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5` (v4) - checks out source
2. `github/codeql-action/init@5c8a8a642e79153f5d047b10ec1cba1d1cc65699` (v3) - initialises CodeQL with the `javascript` language
3. `github/codeql-action/autobuild@5c8a8a642e79153f5d047b10ec1cba1d1cc65699` (v3) - automatically builds the project (no-op for interpreted languages but required for consistency)
4. `github/codeql-action/analyze@5c8a8a642e79153f5d047b10ec1cba1d1cc65699` (v3) - performs the analysis and uploads SARIF results to GitHub Advanced Security

---

## Required Secrets

None. Uses the default `GITHUB_TOKEN` (implicit).

---

## Permissions

| Scope | Level |
|-------|-------|
| `contents` | `read` |
| `security-events` | `write` |
| `actions` | `read` |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | `34e114876b0b11c390a56381ad16ebd13914f8d5` | v4 |
| `github/codeql-action/init` | `5c8a8a642e79153f5d047b10ec1cba1d1cc65699` | v3 |
| `github/codeql-action/autobuild` | `5c8a8a642e79153f5d047b10ec1cba1d1cc65699` | v3 |
| `github/codeql-action/analyze` | `5c8a8a642e79153f5d047b10ec1cba1d1cc65699` | v3 |
