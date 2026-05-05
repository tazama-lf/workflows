# `library-dependency-rollout.yml`

## Purpose

Fires in a library repo when `package.json` is updated on `dev` (i.e. after a PR merges). Reads the new rc version, looks up every registered consumer repo in `library-consumers.json`, updates the exact version pin in each consumer's `package.json`, regenerates `package-lock.json` via `npm install --package-lock-only`, commits both files to a shared `dep/library-dependency-bump` branch in each consumer, and creates or updates a single PR per consumer targeting `dev`.

Multiple library bumps coalesce: if `dep/library-dependency-bump` already exists in a consumer from a prior library rollout, the new commit is pushed on top of the existing branch and the open PR is reused rather than a duplicate being opened.

Only runs for rc versions (e.g. `4.0.0-rc.3`). Stable-version dependency resolution is handled by `release-train.yml` in each consumer repo.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branch: `dev`, path: `package.json` |
| `workflow_dispatch` | manual re-run |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Node version | `20` |
| Typical duration | ~2–5 min (scales with number of consumers) |
| Concurrency | `library-dependency-rollout-<repository>`, `cancel-in-progress: false` |
| Permissions | `contents: read` (all cross-repo operations use `GH_TOKEN`) |

---

## Jobs

### `rollout`

**Steps:**

1. `actions/checkout@v6.0.2` - checks out `dev` in the library repo
2. `Read library package.json` - extracts `name` and `version` from the library's own `package.json`
3. `Skip if not an rc version` - exits gracefully if the version does not contain `-rc.` (stable merges are handled by `release-train.yml`)
4. `Set up Git signing` - configures SSH commit signing using `SSH_SIGNING_KEY`, same pattern as `sync-workflows.yml`
5. `actions/setup-node@v6.3.0` - installs Node 20
6. `Fetch consumer catalog` - downloads `library-consumers.json` from `tazama-lf/workflows@dev` via the GitHub Contents API
7. `Roll out to consumers` - for each consumer in the catalog:
   - Clones the consumer repo (`--depth=50`)
   - Checks out `dev`; verifies `package.json` exists and contains the library as a dependency
   - Creates or checks out the `dep/library-dependency-bump` branch
   - Updates the exact version pin in `dependencies` or `devDependencies` using `jq` (rewrites the file; formatting and key ordering may change)
   - Configures `~/.npmrc` for `@tazama-lf` and `@frmscoe` GitHub Packages scopes
   - Runs `npm install --package-lock-only --ignore-scripts` (3 attempts, 30 s delay between retries)
   - Commits `package.json` + `package-lock.json` with SSH signing and a DCO `Signed-off-by` trailer
   - Pushes with `--force-with-lease` to `dep/library-dependency-bump`
   - If an open PR already exists from `dep/library-dependency-bump → dev`, logs the PR URL (new commit is already in it)
   - Otherwise creates a new PR with title `chore(deps): bump library dependencies`, a body table listing all bumped packages on the branch, and requests a reviewer via `GH_USERNAME`
8. Writes a job summary table showing each consumer: bumped, skipped, or failed

**Per-consumer skip conditions:**
- Could not clone repo
- No `dev` branch
- No `package.json` on `dev`
- Library not listed in `dependencies` or `devDependencies`
- `npm install --package-lock-only` failed after 3 retries (warning, not failure)
- Push rejected due to concurrent rollout (warning - re-run the workflow)

Consumer failures are warnings only and do not fail the overall job.

---

## Consumer Catalog (`library-consumers.json`)

Located at the root of `tazama-lf/workflows`. Fetched at runtime by the rollout workflow via the GitHub Contents API - no library repo stores or owns the consumer list. Structure:

```json
{
  "@tazama-lf/frms-coe-lib": {
    "source-repo": "frms-coe-lib",
    "consumers": [
      { "org": "tazama-lf", "repo": "auth-service" },
      { "org": "frmscoe", "repo": "rule-001" }
    ]
  }
}
```

The catalog is bootstrapped by `audit-library-consumers.js` (in `C:\DevTools\GitHub\`) and maintained manually thereafter. When a new consumer repo is added to the ecosystem, add its entry to `library-consumers.json` and open a PR to `dev` in `tazama-lf/workflows`. You do not need to touch any library repo - the next time any library merges to `dev`, the rollout will automatically include the new consumer.

---

## Reserved Branch Name

`dep/library-dependency-bump` is a reserved branch name in all consumer repos, managed exclusively by this workflow. Do not use this name for regular development contributions - the rollout will push over it.

---

## Multi-Library Coalescence

When multiple libraries are bumped in quick succession:

1. `frms-coe-lib` merges → rollout creates `dep/library-dependency-bump` in each consumer and opens a PR.
2. `frms-coe-startup-lib` merges → rollout detects the existing branch and open PR, pushes an additional commit, and logs the PR URL. No duplicate PR is created.
3. The `dep/library-dependency-bump` branch now contains commits for both bumps; the existing PR is reused but its body is not updated.

**Race condition:** If two library rollouts push to the same consumer branch concurrently, the second push may fail with `--force-with-lease`. In that case, re-run the workflow for the failing library to retry.

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|---------|
| `SSH_SIGNING_KEY` | repo | Base64-encoded Ed25519 private key for signing commits (same key as `sync-workflows.yml`) |
| `GH_TOKEN` | org | Clone, push, and create PRs in consumer repos across both `tazama-lf` and `frmscoe` orgs; fetch `library-consumers.json` |
| `GH_TOKEN_LIB` | org | Read from GitHub Packages during `npm install --package-lock-only` |
| `GH_USERNAME` | org | GitHub username to request as PR reviewer |

---

## Sync Distribution

| Group | Behaviour |
|-------|-----------|
| `PUBLISH_REPOS` | Receives this file (publish-capable repos: library repos + `rule-901`, `rule-902`) |
| All other groups | Does not receive this file |
