# `package-rule-rc.yml`

## Purpose

Reusable workflow that automates building and pushing a release-candidate Docker image for a rule processor. It clones `rule-executer` (dev branch), patches the rule number and version, builds the image, and pushes it with both a versioned prerelease tag (e.g. `1.0.0-rc.2`) and a floating `:rc` pointer.

Called from a caller stub `package-rule-rc.yml` in each rule repo rather than being copied in full.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | called from rule repo caller stub |

---

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `rule_number` | yes | Zero-padded rule number (e.g. `"001"`, `"901"`) |
| `rule_org` | yes | GitHub org owning the rule repo (`"tazama-lf"` or `"frmscoe"`) |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Node version | `20` |
| Typical duration | ~5–10 min |
| Concurrency | none |
| Permissions | `contents: read` |

---

## Jobs

### `automate-rule-executer`

**Steps:**

1. `actions/checkout@v4` - checks out rule repo source
2. `actions/setup-node@v4` - Node 22
3. `Read rule version from package.json` - reads `version`; fails if version is NOT a prerelease (`-` suffix required - guards against RC build running on a stable version)
4. `Clone Rule Executer repository (dev branch)` - clones `tazama-lf/rule-executer@dev`
5. `Prepare rule-executer-<N>` - copies cloned directory
6. `Modify package.json and Dockerfile for rule <N>` - uses a `case` statement on `rule_org` (`frmscoe` → `@frmscoe` scope + `npm:@frmscoe/rule-*`; `tazama-lf` → `@tazama-lf` scope + `npm:@tazama-lf/rule-*`; any other value → `exit 1`) to patch the rule dependency, `ENV RULE_NAME`, `ENV APM_SERVICE_NAME`; validates each substitution succeeded with `grep` + `exit 1`
7. `Regenerate package-lock.json for rule <N>` - deletes the stale lock file, runs `npm install --package-lock-only --ignore-scripts` to regenerate it from the modified `package.json`, then validates the lock file references the correct rule module (see [Lock file design note](#lock-file-design-note) below)
8. `Build and push RC Docker image` - builds once; tags with `VERSION` and `:rc`; pushes both
9. `Send Slack notification` - posts to `SLACK_WEBHOOK_URL`

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|---------|
| `GH_TOKEN_LIB` | org | `npm install` for private packages; checkout token |
| `DOCKER_USERNAME` | org | Docker Hub login |
| `DOCKER_PASSWORD` | org | Docker Hub password |
| `SLACK_WEBHOOK_URL` | org | Slack notification |

---

## Sync Distribution

| Group | Behaviour |
|-------|-----------|
| `RULE_REPOS` (`rule-901`, `rule-902`) | Receives a **caller stub** - the canonical reusable definition lives only in `tazama-lf/workflows` |
| All other repos | **Not distributed** |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | tag ref `v4` | - |
| `actions/setup-node` | tag ref `v4` | - |

---

## Known Limitations / Notes

- `dependabot[bot]` actors are excluded.
- Rule repo caller stubs also trigger on `repository_dispatch: types: [rule-executer-update]`, enabling rule images to be rebuilt when `rule-executer` itself changes without needing a new commit in the rule repo.
- The `:rc` tag is a floating pointer overwritten on every push to `dev`. Use the versioned tag (e.g. `1.0.0-rc.2`) for reproducible deployments.

---

## Lock file design note

### Why the lock file must be regenerated

The Docker build runs `npm ci`, which is strictly deterministic: it installs exactly what `package-lock.json` specifies and ignores `package.json` entirely. The `sed` step in this workflow updates `package.json` to reference the correct rule module (e.g. `@tazama-lf/rule-902`), but the cloned lock file still references whichever rule was in `rule-executer` at clone time (e.g. `@tazama-lf/rule-901`). Without regenerating the lock file, `npm ci` installs the wrong rule module regardless of what `package.json` says.

### Why `--package-lock-only --ignore-scripts`

- `--package-lock-only` - writes only the lock file; does not create `node_modules` locally. The actual install is done inside the Docker build via `npm ci`, so installing locally is wasted work.
- `--ignore-scripts` - `rule-executer` has a `prepare` lifecycle script that runs `husky`. Since `node_modules` is absent, `husky` is not found and npm exits with code 127. `--ignore-scripts` skips all lifecycle hooks.

### Post-generate validation

After regeneration, the step greps the lock file for `"name": "${EXPECTED_SCOPE}/rule-${RULE_NUM}"`. If the entry is missing (e.g. the module was not published yet, or auth to the npm registry failed silently), the step fails with a clear error before the Docker build starts. Without this check, a silent failure would cause `npm ci` to error inside Docker with a much less obvious message.

### Incident (May 2026)

The original workflow used a plain `npm install` without deleting the lock file first. Because `npm ci` is deterministic on the lock file, a Docker image for `rule-902` was built and pushed containing the `rule-901` module. The mismatch was caught at runtime by the identity check added to `rule-executer` (PR #408), which compares `RULE_ID` exported by the loaded module against the `RULE_NAME` environment variable and refuses to start if they differ. The container logged the identity mismatch and exited on startup.

**Root cause chain:**
1. `package-rule-rc.yml` ran `sed` on `package.json` only - the lock file was not updated.
2. Docker's `npm ci` followed the lock file and installed `rule-901` into the `rule-902` image.
3. `rule-executer` started, loaded the `rule` module alias, read `RULE_ID = '901'`, compared it to `RULE_NAME = '902'`, and exited with an identity mismatch error.

**Fix applied:** PRs #118 and #119 in `tazama-lf/workflows`, PR #89 in `frmscoe/workflows`.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all rule repos use the canonical reusable workflow via their caller stub)_ |
