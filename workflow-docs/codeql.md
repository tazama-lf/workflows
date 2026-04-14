# `codeql.yml`

## Purpose

Runs GitHub CodeQL semantic analysis on JavaScript/TypeScript source code, scanning for vulnerabilities and quality issues. Results are surfaced in the GitHub Security tab.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[dev, main]` |
| `pull_request` | branches: `[dev, main]` |
| `schedule` | `34 0 * * 4` (Thursday 00:34 UTC) |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~3–5 min |
| Concurrency | none |
| Permissions | `actions: read`, `contents: read`, `security-events: write` |

---

## Jobs

### `analyze` - Analyze

**Matrix:** `language: [javascript]`

**Steps:**

1. `actions/checkout@v4` - checks out source
2. `github/codeql-action/init@v3` - initialises CodeQL toolchain for JavaScript
3. `github/codeql-action/autobuild@v3` - automatically builds the project
4. `github/codeql-action/analyze@v3` - performs analysis and uploads results

---

## Required Secrets

None (uses default `GITHUB_TOKEN`).

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
| `github/codeql-action/init` | tag ref `v3` | - |
| `github/codeql-action/autobuild` | tag ref `v3` | - |
| `github/codeql-action/analyze` | tag ref `v3` | - |

---

## Known Limitations / Notes

- Language matrix is fixed to `javascript`; CodeQL treats JS and TS together under the `javascript` language key - no change needed for TypeScript repos.
- `dependabot[bot]` actors are excluded.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
