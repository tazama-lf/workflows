# `sync-workflows.yml`

## Purpose

Propagates canonical workflow files from this repository to all configured target repos. When a PR to `dev` is opened or updated, it clones each target repo, copies the applicable workflow files according to per-file sync rules, and opens a `sync-workflows-update` PR in each target repo. `sync-workflows.yml` and `node.js.yml` are explicitly excluded from the bundle.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `pull_request` | branches: `[dev]` (fires on open, update, and close) |
| `workflow_dispatch` | manual |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~10–30 min (scales with number of target repos) |
| Concurrency | none |
| Permissions | default (plus `GH_TOKEN` for cross-repo operations) |

---

## Sync Groups

| Variable | Contents |
|----------|---------|
| `REPOS` | All 26 target repositories (service + library) |
| `SPECIFIC_REPOS` | Library and non-Docker repos that skip `SPECIFIC_FILES` |
| `SPECIFIC_FILES` | `dockerhub-image-build.yml dockerhub-image-build-rc.yml` |
| `PUBLISH_REPOS` | Library repos that receive `publish.yml`, `version-check.yml`, `release-train.yml` but not `scorecard.yml` |
| `RULE_REPOS` | `rule-901`, `rule-902` — receive caller stubs for `package-rule*.yml` instead of the full canonical |

**Org routing:** Library repos (`PUBLISH_REPOS`) are cloned from `tazama-lf`; service repos are currently cloned from `frmscoe`. Full service-repo migration is tracked in [workflows#28](https://github.com/tazama-lf/workflows/issues/28).

---

## Jobs

### `Sync_All_Repos_Common_Workflows`

**Steps:**

1. `actions/checkout@v4` — checks out this workflows repo
2. `Set up Git` — configures git identity for commits
3. `Install GitHub CLI` — downloads and installs `gh` CLI v2.14.7
4. `Get PR author details` — captures author name and email for commit attribution
5. `Sync Workflows to Other Repos` — main loop: clones each repo, checks out or creates `sync-workflows-update` branch, applies per-file sync rules, commits changes, pushes, opens PR

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|-------|
| `GH_TOKEN` | org | Clone, push, and open PRs against target repos |
| `GH_USERNAME` | org | PR reviewer assignment |

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| **Not synced** | This file is explicitly removed from the sync bundle (`rm temp-workflows/sync-workflows.yml`) |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|----------|
| `actions/checkout` | tag ref `v4` | — |

---

## Known Limitations / Notes

- Service repo org URLs still use `frmscoe` (not `tazama-lf`); tracked in [workflows#28](https://github.com/tazama-lf/workflows/issues/28).
- `gh` CLI is pinned to v2.14.7 via a direct tarball download; should be updated periodically.
- The workflow fires on all `pull_request` events to `dev`, not just merged ones. This means unmerged PRs trigger sync branches in target repos; reviewers in those repos should not merge `sync-workflows-update` PRs until the source PR is merged.
- `dependabot[bot]` actors are excluded.

---

## Repository Overrides

Not applicable — this workflow is canonical-only and is never distributed.
