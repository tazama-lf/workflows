# `encoding-check-ci.yml`

## Purpose

Centralised reusable workflow that scans every file added or modified in a pull request for non-UTF-8-no-BOM encodings. Emits inline GitHub annotations for any file starting with a UTF-16 LE, UTF-16 BE, or UTF-8 BOM byte sequence. Called by the [`encoding-check.yml`](encoding-check.md) caller stub in every consumer repo. **Not synced to consumer repos.**

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by `encoding-check.yml` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | < 30 s |
| Concurrency | none |
| Permissions | `contents: read` (default) |

---

## Jobs

### `encoding-check`

**Skip condition:** actor is `dependabot[bot]`, `dependabot-preview[bot]`, or `github-actions[bot]`

**Steps:**

1. `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5` (v4) - full history checkout (`fetch-depth: 0`)
2. `Check file encodings` - collects changed files via `git diff --diff-filter=d` (excludes deleted files); for each file reads the first 3 bytes using `xxd -p`; compares against BOM patterns; emits `::error file=<path>::` annotations for each violation; fails the job if any violations found

**BOM patterns detected:**

| BOM bytes | Encoding |
|-----------|----------|
| `FF FE` | UTF-16 LE |
| `FE FF` | UTF-16 BE |
| `EF BB BF` | UTF-8 BOM |

**Note on binary files:** UTF-16 files contain NUL bytes and are classified as binary by git, which would suppress a `--diff-filter=text` check. The BOM byte pattern itself is used as the discriminator instead - genuine binary files (images, compiled outputs, etc.) do not start with any of the three BOM sequences.

---

## Required Secrets

None. Uses the default `GITHUB_TOKEN` (implicit).

---

## Permissions

| Scope | Level |
|-------|-------|
| `contents` | `read` |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | `34e114876b0b11c390a56381ad16ebd13914f8d5` | v4 |
