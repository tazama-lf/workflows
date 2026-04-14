# `package-rule.yml`

## Purpose

Reusable workflow that automates building and pushing a stable Docker image for a rule processor. It clones `rule-executer` (main branch), patches the rule number and version into `package.json` and `Dockerfile`, builds the image, and pushes it with both a versioned stable tag (e.g. `1.0.0`) and a floating `:latest` pointer.

Called from a caller stub `package-rule.yml` in each rule repo rather than being copied in full.

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
2. `actions/setup-node@v4` - Node 20
3. `Read rule version from package.json` - reads `version`; fails if version is a prerelease (guards against stable build running on a prerelease version)
4. `Clone Rule Executer repository (main branch)` - clones `tazama-lf/rule-executer@main`
5. `Prepare rule-executer-<N>` - copies cloned directory
6. `Modify package.json and Dockerfile for rule <N>` - uses a `case` statement on `rule_org` (`frmscoe` → `@frmscoe` scope + `npm:@frmscoe/rule-*`; `tazama-lf` → `@tazama-lf` scope + `npm:@tazama-lf/rule-*`; any other value → `exit 1`) to patch the rule dependency, `ENV RULE_NAME`, `ENV APM_SERVICE_NAME`; validates each substitution succeeded
7. `Install dependencies` - `npm install` in the patched directory (uses `npm install` rather than `npm ci` because the preceding `sed` step modifies `package.json`, invalidating the lockfile)
8. `Build and push stable Docker image` - builds once; tags with `VERSION` and `:latest`; pushes both
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
- Fails explicitly if version IS a prerelease - the `version-check.yml` guard on `main` PRs provides a second line of defence for library repos, but this redundant check prevents an accidental stable-build run if branch protection is bypassed.
- The `checkov:skip=CKV_GHA_7` annotation suppresses a false-positive: the `version` input variable is emitted by a `node -p` read of `package.json` and controls only the Docker tag, not the build artifact source.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all rule repos use the canonical reusable workflow via their caller stub)_ |
