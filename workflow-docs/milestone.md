# `milestone.yml`

## Purpose

Closes a GitHub milestone and triggers the `release.yml` workflow via `repository_dispatch`, linking milestone completion to the automated release process.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_dispatch` | input: `milestoneId` (required) |

---

## Execution Context

| Property | Value |
|----------|
| Runner | `ubuntu-latest` |
| Typical duration | ~30 s |
| Concurrency | none |
| Permissions | default (`GITHUB_TOKEN`) |

---

## Jobs

### `close_milestone` — close milestone and trigger release

**Steps:**

1. `actions/checkout@v2` — checks out source
2. `Set up environment variables` — sets `ACCESS_TOKEN`, `MILESTONE_NUMBER`, `API_URL`
3. `Close Milestone` — calls `PATCH /repos/:repo/milestones/:number` with `{"state": "closed"}`
4. `Trigger Release Workflow` — `peter-evans/repository-dispatch@v1` fires `release` event with `milestone_number` payload

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
| `peter-evans/repository-dispatch` | tag ref `v1` | — |

---

## Known Limitations / Notes

- `dependabot[bot]` actors are excluded.
- Uses `actions/checkout@v2` — should be upgraded to `v4` to align with all other workflows.
- `peter-evans/repository-dispatch@v1` is not pinned to a SHA; should be pinned per GitHub hardening recommendations.
- The milestone is closed before the release workflow is confirmed to have started; if the dispatch fails, the milestone remains closed without a release created.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
