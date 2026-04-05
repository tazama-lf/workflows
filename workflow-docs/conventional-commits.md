# `conventional-commits.yml`

## Purpose

Validates the PR title against the Conventional Commits specification and automatically applies a corresponding GitHub label (e.g. `bug`, `enhancement`, `CI/CD`) to the PR.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `pull_request` | types: `[opened, synchronize, reopened, edited]` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~20 s |
| Concurrency | none |
| Permissions | default (`GITHUB_TOKEN`) |

---

## Jobs

### `validate-pr-title` — PR Conventional Commit Validation

**Steps:**

1. `actions/checkout@v4` — checks out source
2. `ytanikin/PRConventionalCommits@1.1.0` — validates title; accepted types: `build`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `style`, `test`, `feat!`; applies label on match

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
| `actions/checkout` | tag ref `v4` | — |
| `ytanikin/PRConventionalCommits` | tag ref `1.1.0` | — |

---

## Known Limitations / Notes

- `dependabot[bot]` actors are excluded.
- GitHub labels must exist in the target repo before the action can apply them; the action will silently skip label creation if they are missing.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
