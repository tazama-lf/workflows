# `encoding-check.yml`

## Purpose

Checks every file added or modified in a pull request for non-UTF-8-no-BOM encodings. Fails the PR check and emits inline file annotations if any file starts with a UTF-16 LE (`FF FE`), UTF-16 BE (`FE FF`), or UTF-8 BOM (`EF BB BF`) marker. Preventative only - does not re-encode files automatically.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `pull_request` | types: `opened`, `synchronize`, `reopened` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | < 30 s |
| Concurrency | none (default GitHub behaviour) |
| Permissions | `contents: read` (default) |

---

## Jobs

### `encoding-check`

**Steps:**

1. `actions/checkout@v6.0.2` - checks out the repository with `fetch-depth: 0` so both the base and head SHAs are resolvable
2. `Check file encodings` - for each file added or modified in the PR (deleted files excluded via `--diff-filter=d`):
   - Reads the first 3 bytes using `head -c 3 | xxd -p`
   - Compares the hex prefix against `fffe` (UTF-16 LE), `feff` (UTF-16 BE), and `efbbbf` (UTF-8 BOM)
   - Emits a `::error file=<path>::` annotation for each violation so GitHub displays it inline on the PR
   - Counts all violations and fails the job if any are found, with a remediation message pointing to VS Code's encoding selector

Note: binary detection is not used as a pre-filter. UTF-16 files contain NUL bytes and are classified as binary by git, which would suppress the check. Instead, the BOM pattern itself is the discriminator - genuine binary files (images, compiled outputs, etc.) do not start with any of the three BOM sequences and pass cleanly.

**Skip conditions:**
- PR has no changed files
- Actor is `dependabot[bot]`, `dependabot-preview[bot]`, or `github-actions[bot]`

---

## BOMs Detected

| BOM bytes | Encoding | Error message |
|-----------|----------|---------------|
| `FF FE` | UTF-16 LE | `Non-UTF-8 encoding detected: UTF-16 (BOM: fffe). Re-save the file as UTF-8 without BOM.` |
| `FE FF` | UTF-16 BE | `Non-UTF-8 encoding detected: UTF-16 (BOM: feff). Re-save the file as UTF-8 without BOM.` |
| `EF BB BF` | UTF-8 BOM | `UTF-8 BOM detected (EF BB BF). Re-save the file as UTF-8 without BOM.` |

---

## Remediation

In VS Code: click the encoding indicator in the status bar (bottom-right, shows e.g. `UTF-16 LE`) → **Save with Encoding** → **UTF-8**.

In other editors, use the "Save As" / encoding option and select **UTF-8** (not "UTF-8 with BOM").

---

## Required Secrets

None. Uses the default `GITHUB_TOKEN` (implicit) - no explicit secret needed.

---

## Sync Distribution

| Group | Behaviour |
|-------|-----------|
| All repos (`REPOS`) | Receives this file |
