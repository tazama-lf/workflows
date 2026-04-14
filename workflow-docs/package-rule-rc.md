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
2. `actions/setup-node@v4` - Node 20
3. `Read rule version from package.json` - reads `version`; fails if version is NOT a prerelease (`-` suffix required - guards against RC build running on a stable version)
4. `Clone Rule Executer repository (dev branch)` - clones `tazama-lf/rule-executer@dev`
5. `Prepare rule-executer-<N>` - copies cloned directory
6. `Modify package.json and Dockerfile for rule <N>` - uses a `case` statement on `rule_org` (`frmscoe` → `@frmscoe` scope + `npm:@frmscoe/rule-*`; `tazama-lf` → `@tazama-lf` scope + `npm:@tazama-lf/rule-*`; any other value → `exit 1`) to patch the rule dependency, `ENV RULE_NAME`, `ENV APM_SERVICE_NAME`; validates each substitution succeeded
7. `Install dependencies` - `npm install` in the patched directory (uses `npm install` rather than `npm ci` because the preceding `sed` step modifies `package.json`, invalidating the lockfile)
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

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all rule repos use the canonical reusable workflow via their caller stub)_ |
