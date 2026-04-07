# `release.yml`

## Purpose

Automates the GitHub release creation process. Triggered by a `repository_dispatch` event (fired by `milestone.yml`), it determines the release type (major/minor/patch) from commit messages, bumps the version, generates a changelog from merged PRs, creates a GitHub release, and updates `CHANGELOG.md` and `VERSION` in the repository.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `repository_dispatch` | types: `[release]`; payload: `milestone_number` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~1–2 min |
| Concurrency | none |
| Permissions | default (`GITHUB_TOKEN`) |

---

## Jobs

### `release`

**Steps:**

1. `actions/checkout@v2` — checks out `main` with full tag history
2. `Determine Release Type` — parses commit messages; maps `BREAKING CHANGE`/`feat!` → major, `feat:` → minor, all others → patch; uses `git describe --abbrev=0 --tags 2>/dev/null || echo "v0.0.0"` so repos with no tags default to `v0.0.0` rather than failing
3. `Bump Version` — increments the appropriate version component; same `git describe` fallback applied here
4. `Get Milestone Details` — validates `MILESTONE_NUMBER` from `client_payload` is non-empty (exits 1 with an error message if unset) then fetches milestone title and description via GitHub API
5. `Generate Changelog` — compiles changelog from merged PRs since last tag
6. `Display Changelog` — prints to runner log
7. `Attach Changelog to Release` — writes changelog content
8. `Create Release` — creates the GitHub release with the new tag
9. `Update CHANGELOG.md File` — prepends the new changelog entry
10. `Update VERSION File` — writes new version string
## Required Secrets

None (uses auto-provided `GITHUB_TOKEN`).

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| All `REPOS` | Receives this file |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|----------|
| `actions/checkout` | tag ref `v2` | — |

---

## Known Limitations / Notes

- Uses deprecated `::set-output name=...` syntax; should be migrated to `$GITHUB_OUTPUT`.
- Uses `actions/checkout@v2`; should be upgraded to `v4`.
- No actions are pinned to commit SHAs — all use mutable tag refs, which is a supply-chain risk.
- `dependabot[bot]` actors are excluded.
- `git describe` calls use `2>/dev/null || echo "v0.0.0"` fallback so the workflow does not fail on repos that have no tags yet.
- `MILESTONE_NUMBER` is validated non-empty before the GitHub API call; a missing or empty value exits 1 with a clear error rather than silently passing a malformed URL to `curl`.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
