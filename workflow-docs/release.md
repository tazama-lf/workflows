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
2. `actions-ecosystem/action-get-merged-pull-request@v1` — retrieves the last merged PR
3. `actions-ecosystem/action-release-label@v1` — determines release level from PR labels
4. `actions-ecosystem/action-get-latest-tag@v1` — gets the latest semver tag
5. `Determine Release Type` — parses commit messages; maps `BREAKING CHANGE`/`feat!` → major, `feat:` → minor, all others → patch
6. `Bump Version` — increments the appropriate version component
7. `Get Milestone Details` — fetches milestone title and description via GitHub API
8. `Generate Changelog` — compiles changelog from merged PRs since last tag
9. `Display Changelog` — prints to runner log
10. `Attach Changelog to Release` — writes changelog content
11. `Create Release` — creates the GitHub release with the new tag
12. `Update CHANGELOG.md File` — prepends the new changelog entry
13. `Update VERSION File` — writes new version string

---

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
| `actions-ecosystem/action-get-merged-pull-request` | tag ref `v1` | — |
| `actions-ecosystem/action-release-label` | tag ref `v1` | — |
| `actions-ecosystem/action-get-latest-tag` | tag ref `v1` | — |

---

## Known Limitations / Notes

- Uses deprecated `::set-output name=...` syntax; should be migrated to `$GITHUB_OUTPUT`.
- Uses `actions/checkout@v2`; should be upgraded to `v4`.
- No actions are pinned to commit SHAs — all use mutable tag refs, which is a supply-chain risk.
- `dependabot[bot]` actors are excluded.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
