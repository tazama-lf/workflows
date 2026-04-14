# `sync-workflows.yml`

## Purpose

Propagates canonical workflow files from this repository to all configured target repos. When commits land on `dev` (i.e. a PR is merged or a direct push is made), it clones each target repo, copies the applicable workflow files according to per-file sync rules, and opens a `sync-workflows-update` PR in each target repo. `sync-workflows.yml` and `node.js.yml` are explicitly excluded from the bundle.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[dev]` (fires only when commits land on `dev`) |
| `workflow_dispatch` | manual |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~10–30 min (scales with number of target repos) |
| Concurrency | `group: sync-workflows-${{ github.ref }}`, cancel-in-progress |
| Permissions | default (plus `GH_TOKEN` for cross-repo operations) |

---

## Sync Groups

| Variable | Contents |
|----------|---------|
| `REPOS` | All 26 target repositories (service + library) |
| `SPECIFIC_REPOS` | Library and non-Docker repos that skip `SPECIFIC_FILES` |
| `SPECIFIC_FILES` | `dockerhub-image-build.yml dockerhub-image-build-rc.yml` |
| `PUBLISH_REPOS` | Library repos that receive `publish.yml`, `version-check.yml`, `release-train.yml` but not `scorecard.yml` |
| `RULE_REPOS` | `rule-901`, `rule-902` - receive caller stubs for `package-rule*.yml` instead of the full canonical |

**Org routing:** All repos in `REPOS` are cloned from the `tazama-lf` org.

---

## Jobs

### `Sync_All_Repos_Common_Workflows`

**Steps:**

1. `actions/checkout@v4` - checks out this workflows repo
2. `Set up Git` - configures git identity for commits
3. `Get actor details` - captures the triggering actor's name and email for commit attribution; uses the PR author for `pull_request` events and `github.actor` for `push`/`workflow_dispatch` events
4. `Sync Workflows to Other Repos` - main loop: clones each repo, ensures `dev` branch exists (creates from default branch if absent), deletes any existing `sync-workflows-update` branch, creates a fresh `sync-workflows-update` from `dev`, applies per-file sync rules, commits changes, pushes, opens PR. **`sync-workflows-update` is a reserved branch name** - do not use it for regular development contributions.

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
| `actions/checkout` | tag ref `v4` | - |

---

## Known Limitations / Notes

- The workflow fires on `push` to `dev`, so it only runs when commits actually land on the branch (typically after a PR merge). `sync-workflows-update` PRs in target repos should be safe to review and merge as soon as they appear.
- **`sync-workflows-update` is a reserved branch name.** The workflow deletes and recreates it on every run. Do not use this name for regular development contributions; any pushed commits will be discarded on the next sync run.
- Target repos must have a `dev` branch. If absent, the workflow creates one from the repo’s default branch automatically.
- `dependabot[bot]` actors are excluded.

---

## Repository Overrides

Not applicable - this workflow is canonical-only and is never distributed.
