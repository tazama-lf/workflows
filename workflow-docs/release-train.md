# `release-train.yml`

## Purpose

Prepares a library release PR from `dev` → `main`. Given a target stable version, it validates the input, resolves all internal `@tazama-lf`/`@frmscoe` rc dependencies to their latest stable equivalents, bumps `package.json`, regenerates `package-lock.json`, then creates a `release/v<N>` branch and opens a PR — all via the GitHub API so that commits are Verified and satisfy branch protection.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_dispatch` | input: `version` (required, clean semver `X.Y.Z` — no prerelease suffix) |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Node version | `20` |
| Registry | `https://npm.pkg.github.com/` |
| Typical duration | ~2–3 min |
| Concurrency | none |
| Permissions | `contents: write`, `pull-requests: write` |

---

## Jobs

### `prepare-release`

**Steps:**

1. `Validate version input` — rejects prerelease suffixes and non-`X.Y.Z` strings
2. `actions/checkout@v4` — checks out `dev` branch (token: `GH_TOKEN_LIB`)
3. `actions/setup-node@v4` — Node 20, GitHub Packages registry, `@tazama-lf` scope
4. `Add @frmscoe registry scope` — appends registry line to `~/.npmrc`
5. `Resolve internal rc dependencies to stable` — iterates `dependencies`, `devDependencies`, `peerDependencies`; resolves pinned-rc and range-with-rc patterns; fails if `dist-tags.latest` is still a prerelease
6. `Update version in package.json` — writes the workflow input version
7. `Regenerate package-lock.json` — runs `npm install --package-lock-only`
8. `Commit and push to release branch via GitHub API` — creates/resets `release/v<N>` branch at current dev HEAD; builds tree, creates commit, and updates ref via REST API; outputs `branch_name` and `commit_sha`
9. `Open PR to main via GitHub API` — creates PR targeting `main` with reviewers from `GH_USERNAME` secret

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|---------|
| `GH_TOKEN_LIB` | org | API commits, npm install auth, PR creation — classic PAT requires `repo`, `workflow`, `read:packages` |

---

## Sync Distribution

| Group | Behaviour |
|-------|-----------|
| `PUBLISH_REPOS` | Receives this file |
| All service repos (non-`PUBLISH_REPOS`) | **Excluded** |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | tag ref `v4` | — |
| `actions/setup-node` | tag ref `v4` | — |

---

## Known Limitations / Notes

- `checkov:skip=CKV_GHA_7` annotation suppresses a false-positive: the `version` input controls only the release branch name and `package.json` version — not the build artifact source.
- If `release/v<N>` already exists it is force-reset to the current `dev` HEAD, enabling idempotent reruns without manual cleanup.
- The PR body does not include an auto-generated changelog; reviewers should compare `dev` to `main` manually before approving.
- **`GH_TOKEN_LIB` required scopes (classic PAT):** `repo` (covers creating commits via the GitHub REST API, creating/resetting the `release/v<N>` branch, and opening the PR to main — equivalent to `contents: write` + `pull-requests: write` in fine-grained token terms), `workflow` (required when any commit touches `.github/workflows/` files), and `read:packages` (npm install from GitHub Packages). Commits created via the GitHub API with a token bearing the `repo` scope are automatically marked **Verified** by GitHub — no GPG signing key is needed on the runner.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all PUBLISH_REPOS use the canonical version)_ |
