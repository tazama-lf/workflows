<!-- SPDX-License-Identifier: Apache-2.0 -->

# tazama-lf/workflows

Canonical GitHub Actions workflows for the Tazama project. This repository is the **single source of truth** for CI/CD automation across all active Tazama repositories in both the `tazama-lf` and `frmscoe` organisations.

Workflow files are distributed to target repositories automatically by [`sync-workflows.yml`](.github/workflows/sync-workflows.yml) on every pull request to `dev` in this repo. The `frmscoe/workflows` repo is a manually-maintained mirror of the relevant subset of files for `frmscoe` rule repos, seeded from this repo.

For detailed documentation on any individual workflow, see the [`workflow-docs/`](workflow-docs/) directory. A template for new entries is at [`workflow-docs/docs-template.md`](workflow-docs/docs-template.md).

---

## Repository Classes

Each repository in the Tazama ecosystem belongs to one class. The class determines which workflows it receives, which SDLC path applies, and whether it builds Docker images, publishes npm packages, or both.

| Class | Repos | Output | Notes |
|-------|-------|--------|-------|
| **Service repos** | `auth-service`, `typology-processor`, `event-director`, `event-flow`, `event-sidecar`, `lumberjack`, `nats-utilities`, `admin-service`, `tms-service`, `transaction-aggregation-decisioning-processor` | Docker image | Publish to Docker Hub; receive full workflow set including Docker build workflows |
| **Other service repos** | `relay-service`, `batch-ppa`, `rule-executer`, `Full-Stack-Docker-Tazama` | — | In `SPECIFIC_REPOS`; do not receive `dockerhub-image-build*.yml` |
| **Library repos** | `frms-coe-lib`, `frms-coe-startup-lib`, `auth-lib`, `auth-lib-provider-keycloak`, `tcs-lib`, `audit-lib`, `relay-service-integration-nats`, `relay-service-integration-rest`, `relay-service-integration-kafka`, `relay-service-integration-rabbitmq` | npm package | Publish to GitHub Packages under `@tazama-lf` scope |
| **Rule repos — tazama-lf** | `rule-901`, `rule-902` | Docker image + npm package | Also in `PUBLISH_REPOS`; use `package-rule*.yml` caller stubs for Docker builds |
| **Rule repos — frmscoe** | `rule-001` through `rule-091` (33 active repos) | Docker image | Managed via [`frmscoe/workflows`](https://github.com/frmscoe/workflows); receive Docker builds via `package-rule*.yml` caller stubs |
| **Workflow repos** | `tazama-lf/workflows` (this repo), `frmscoe/workflows` | — | Canonical; not synced to |

---

## Standard PR Check Suite

The following checks run automatically on pull requests across all repo classes. They are defined once here and referenced throughout the SDLC sections below.

| Workflow | What it checks |
|----------|---------------|
| `branch-target-check.yml` | PR base branch must be `dev` or `release/v*` when targeting `main` — **fires on PRs to `main` only** |
| `conventional-commits.yml` | PR title is validated against the [Conventional Commits](https://www.conventionalcommits.org/) specification |
| `dco-check.yml` | All commits carry a DCO `Signed-off-by` trailer — ⚠️ [known issue #37](https://github.com/tazama-lf/workflows/issues/37) |
| `gpg-verify.yml` | All commits are GPG-signed |
| `codacy.yml` | Static analysis via Codacy CLI — ⚠️ [known issue #38](https://github.com/tazama-lf/workflows/issues/38) |
| `codeql.yml` | GitHub CodeQL SAST security scan |
| `njsscan.yml` | Node.js-specific security scan (semgrep rules) |
| `dependency-review.yml` | Flags new dependencies with known CVEs or licence restrictions |
| `node.js.yml` | Build, lint, and test on Node 20 — **not synced; each repo maintains its own copy** |

> Pre-commit tooling (local linting, formatting, commit-msg hooks) is developer-local and not managed here. See the project [contribution guide](https://github.com/tazama-lf/tazama-documentation) for local setup guidance.

---

## SDLC Flows

### 1. Library repos (PUBLISH_REPOS)

Library repos publish versioned npm packages under the `@tazama-lf` scope. They do not produce Docker images. The versioning cycle uses rc pre-releases on `dev` and promotes to a stable release on `main`.

#### Feature development → dev

1. **Developer** — develops changes on a feature branch.
2. **Developer — MANUAL** — bumps `version` in `package.json` to `X.Y.Z-rc.N`.
3. **Developer** — opens pull request targeting `dev`.
4. **AUTO** — [standard PR check suite](#standard-pr-check-suite) fires.
5. **Reviewer — MANUAL** — reviews, approves, merges PR to `dev`.
6. **AUTO** — `publish.yml` fires on `push: dev`; detects the `-rc` suffix; publishes the package to GitHub Packages under the `rc` dist-tag.

#### Release → main

1. **Developer — MANUAL** — triggers `release-train.yml` via `workflow_dispatch` from `dev`; enters the target stable version (e.g. `4.0.0`, no prerelease suffix).
2. **AUTO** — `release-train.yml` resolves all `-rc.*` dependencies to their stable equivalents, regenerates `package-lock.json`, and opens a `release/vX.Y.Z → main` PR. Fails if any dependency has no stable release yet.
3. **Developer — MANUAL** — in the release PR branch, strips the `-rc.N` suffix from `version` in `package.json`.
4. **AUTO** — `version-check.yml` fires on the PR targeting `main`; blocks merge if the version still contains a prerelease suffix.
5. **AUTO** — full standard PR check suite also fires on the `main`-targeting PR.
6. **Reviewer — MANUAL** — reviews and merges the release PR to `main`.
7. **AUTO** — `publish.yml` fires on `push: main`; detects a clean semver; publishes the package under the `latest` dist-tag.

---

### 2. Service repos (Docker-building)

Service repos produce versioned Docker images. They do not publish npm packages.

#### Feature development → dev

1. **Developer — MANUAL** — updates library dependency versions in `package.json` to consume any new rc or stable library releases (this step follows the [library release cycle](#1-library-repos-publish_repos) upstream).
2. **Developer** — develops changes on a feature branch.
3. **Developer** — opens pull request targeting `dev`.
4. **AUTO** — [standard PR check suite](#standard-pr-check-suite) fires, plus `dockerfile-linter.yml` if a `Dockerfile` was modified.
5. **Reviewer — MANUAL** — reviews, approves, merges PR to `dev`.
6. **AUTO** — `dockerhub-image-build-rc.yml` fires on `push: dev`; builds and pushes the Docker image tagged `:rc` to Docker Hub.
7. **AUTO** — `scorecard.yml` fires on `push: dev`; runs OSSF supply-chain checks (results published to the Security tab only on `main`, schedule, and `branch_protection_rule` triggers).

#### Release → main

1. **Developer** — opens pull request `dev → main`.
2. **AUTO** — standard PR check suite fires.
3. **Reviewer — MANUAL** — reviews, approves, merges to `main`.
4. **AUTO** — `dockerhub-image-build.yml` fires on `push: main`; reads `version` from `package.json`; builds and pushes the Docker image tagged `:X.Y.Z` to Docker Hub.
5. **AUTO** — `sbom.yml` fires on `push: main`; generates a Software Bill of Materials from the Docker image — ⚠️ [known issue #39](https://github.com/tazama-lf/workflows/issues/39).
6. **Release manager — MANUAL** — triggers `milestone.yml` via `workflow_dispatch` in the service repo, supplying the milestone ID.
7. **AUTO** — `milestone.yml` closes the milestone and fires `release.yml` via `repository_dispatch`.
8. **AUTO** — `release.yml` determines the version bump from commit messages, generates a changelog from merged PRs, and creates the GitHub release with the changelog as the release body (no `CHANGELOG.md` or `VERSION` files are written to the repository) — ⚠️ [known issue #40](https://github.com/tazama-lf/workflows/issues/40).

---

### 3. Other service repos (no Docker CI build)

`relay-service`, `batch-ppa`, `rule-executer`, and `Full-Stack-Docker-Tazama` follow the same feature development and PR check flow as Docker-building service repos but do **not** receive `dockerhub-image-build*.yml` or `sbom.yml`. Their build and release processes (if any) are managed outside this workflow set.

---

### 4. Rule repos — tazama-lf (rule-901, rule-902)

tazama-lf rule repos are both library repos **and** Docker image producers. They follow the full library release cycle for npm publishing (including `release-train.yml`, `publish.yml`, and `version-check.yml`) and additionally build Docker images via the `package-rule*.yml` reusable workflows.

1. **Merged to `dev`** — same as library repos: `publish.yml` fires and publishes the rc npm package.
2. **AUTO** — `package-rule-rc.yml` caller stub fires on `push: dev`; calls the reusable workflow at `tazama-lf/workflows/.github/workflows/package-rule-rc.yml@dev`; builds and pushes the Docker image tagged `:rc`.
3. **Release to `main`** — same as library repos: `release-train.yml` resolves deps, opens release PR, `version-check.yml` guards the merge.
4. **Merged to `main`** — `publish.yml` fires and publishes the stable npm package.
5. **AUTO** — `package-rule.yml` caller stub fires on `push: main`; calls the reusable workflow; builds and pushes Docker images tagged `:X.Y.Z` and `:latest`.

---

### 5. Rule repos — frmscoe (rule-001 through rule-091)

frmscoe rule repos reside in the `frmscoe` organisation and are managed by [`frmscoe/workflows`](https://github.com/frmscoe/workflows), which is a manually-maintained mirror of the relevant subset of workflows from this repo. frmscoe rule repos build Docker images via `package-rule*.yml` caller stubs (referencing `frmscoe/workflows` as the reusable workflow source) but do not use `dockerhub-image-build*.yml` or `dockerfile-linter.yml`.

**Workflows frmscoe rule repos receive:** `branch-target-check.yml`, `codacy.yml`, `codeql.yml`, `conventional-commits.yml`, `dco-check.yml`, `dependency-review.yml`, `gpg-verify.yml`, `milestone.yml`, `njsscan.yml`, `node.js.yml`, `package-rule-rc.yml` (caller stub), `package-rule.yml` (caller stub), `publish.yml`, `release-train.yml`, `release.yml`, `sbom.yml`, `scorecard.yml`, `version-check.yml`.

**Not received:** `dockerfile-linter.yml`, `dockerhub-image-build.yml`, `dockerhub-image-build-rc.yml`.

**Sync trigger in frmscoe/workflows:** `push: dev` (not `pull_request` — sync fires after merge, not on PR open).

#### SDLC

1. **Developer** — develops changes on a feature branch.
2. **Developer** — opens pull request targeting `dev`.
3. **AUTO** — [standard PR check suite](#standard-pr-check-suite) fires.
4. **Reviewer — MANUAL** — reviews, approves, merges to `dev`.
5. **AUTO** — `package-rule-rc.yml` caller stub fires on `push: dev`; builds and pushes the rule Docker image tagged `:rc`.
6. **Developer** — opens pull request `dev → main` for the release.
7. **AUTO** — standard PR check suite fires.
8. **Reviewer — MANUAL** — reviews, approves, merges to `main`.
9. **AUTO** — `package-rule.yml` caller stub fires on `push: main`; builds and pushes Docker images tagged `:X.Y.Z` and `:latest`.

---

### 6. Canonical workflow changes (this repo)

Changes to this repo propagate to all 26 target repositories. This is the highest-impact SDLC path.

1. **DevOps** — modifies workflow files in `.github/workflows/`; updates the corresponding `workflow-docs/` entry.
2. **DevOps** — opens pull request targeting `dev`.
3. **AUTO** — standard PR check suite fires against this repo.
4. **AUTO** — `sync-workflows.yml` fires; opens `sync-workflows-update` PRs in all 26 target repos — ⚠️ [known issue #36](https://github.com/tazama-lf/workflows/issues/36): fires on PR open, not only on merge. **Do not merge sync PRs in target repos until the source PR here is confirmed merged.**
5. **Reviewer — MANUAL** — reviews and merges the source PR to `dev` in this repo.
6. **Reviewers in target repos — MANUAL** — merge `sync-workflows-update` PRs in each target repo.
7. **DevOps — MANUAL** — applies the same changes to [`frmscoe/workflows`](https://github.com/frmscoe/workflows) via a separate PR (no automated mirror exists between the two workflow repos).
8. **AUTO** — once merged to `dev` in `frmscoe/workflows`, its `sync-workflows.yml` fires on `push: dev` and distributes the changes to all 33 frmscoe rule repos.

---

## Canonical Workflow Reference

Triggers shown are in the context of the **target repo** where each workflow is installed and runs.

| Workflow file | Purpose | Trigger (in target repo) | Synced to |
|--------------|---------|--------------------------|-----------|
| `branch-target-check.yml` | Enforce `dev` (or `main` for `release/v*`) as PR target | `pull_request` | All repos |
| `codacy.yml` | Codacy static analysis | `push`, `pull_request` | All repos |
| `codeql.yml` | GitHub CodeQL SAST | `push: [dev,main]`, `pull_request: [dev,main]`, schedule | All repos |
| `conventional-commits.yml` | Validate Conventional Commits spec | `pull_request` | All repos |
| `dco-check.yml` | Verify DCO Signed-off-by on commits | `pull_request` | All repos |
| `dependency-review.yml` | Flag CVEs and licence issues in new deps | `pull_request` | All repos |
| `dockerfile-linter.yml` | Hadolint lint of Dockerfiles | `pull_request` | All repos (no-op where no `Dockerfile` exists) |
| `dockerhub-image-build-rc.yml` | Build and push `:rc` Docker image | `push: [dev]` | Service repos only (not SPECIFIC_REPOS) |
| `dockerhub-image-build.yml` | Build and push versioned Docker image | `push: [main]` | Service repos only (not SPECIFIC_REPOS) |
| `gpg-verify.yml` | Verify GPG signature on commits | `pull_request` | All repos |
| `milestone.yml` | Close a milestone and trigger `release.yml` | `workflow_dispatch` | All repos |
| `njsscan.yml` | Node.js security scan (semgrep) | `push`, `pull_request` | All repos |
| `node.js.yml` | Node 20 CI: build, lint, test | `push: [dev,main]`, `pull_request: [dev,main]` | **Not synced** — each repo maintains its own copy |
| `package-rule-rc.yml` | Reusable: build and push `:rc` Docker image for a rule processor | `workflow_call` | Not synced directly; caller stubs distributed to `RULE_REPOS` |
| `package-rule.yml` | Reusable: build and push `:latest`/`:X.Y.Z` Docker images for a rule processor | `workflow_call` | Not synced directly; caller stubs distributed to `RULE_REPOS` |
| `publish.yml` | Publish npm package to GitHub Packages | `push: [main]`, `workflow_dispatch` | `PUBLISH_REPOS` only |
| `release-train.yml` | Resolve rc deps, prepare release PR, bump version | `workflow_dispatch` | `PUBLISH_REPOS` only |
| `release.yml` | Create GitHub release with auto-generated changelog as release body | `repository_dispatch: [release]` (from `milestone.yml`) | All repos |
| `sbom.yml` | Generate SBOM from Docker image | `push: [main]` | All repos — ⚠️ [known issue #39](https://github.com/tazama-lf/workflows/issues/39) |
| `scorecard.yml` | OSSF Scorecard supply-chain security | `push: [main,dev]`, schedule (weekly), `branch_protection_rule` | Service repos only (not `PUBLISH_REPOS`) |
| `sync-workflows.yml` | Distribute canonical workflows to all target repos | `pull_request: [dev]`, `workflow_dispatch` | **Not synced** — canonical-only |
| `version-check.yml` | Block PR to `main` if `package.json` version has a prerelease suffix | `pull_request: [main]` | `PUBLISH_REPOS` only |

---

## Sync Distribution

`sync-workflows.yml` uses four groups to control which workflows each target repo receives.

| Group | Members | Behaviour |
|-------|---------|-----------|
| `REPOS` | All 26 tazama-lf target repos | Receive all workflows except those explicitly excluded |
| `SPECIFIC_REPOS` | All library repos + `relay-service`, `batch-ppa`, `rule-executer`, `Full-Stack-Docker-Tazama` | Skip `dockerhub-image-build.yml` and `dockerhub-image-build-rc.yml` |
| `PUBLISH_REPOS` | All library repos + `rule-901`, `rule-902` | Additionally receive `publish.yml`, `version-check.yml`, `release-train.yml`; skip `scorecard.yml` |
| `RULE_REPOS` | `rule-901`, `rule-902` | Receive caller stubs for `package-rule*.yml` instead of the full reusable workflow definition |

**Always excluded from the sync bundle:**

| File | Reason |
|------|--------|
| `sync-workflows.yml` | Canonical-only; never distributed to target repos |
| `node.js.yml` | Each repo maintains its own copy to allow per-repo customisation |

**Full `REPOS` list (26 repos):** `relay-service`, `auth-service`, `typology-processor`, `event-director`, `event-sidecar`, `lumberjack`, `nats-utilities`, `batch-ppa`, `admin-service`, `tms-service`, `transaction-aggregation-decisioning-processor`, `Full-Stack-Docker-Tazama`, `rule-executer`, `event-flow`, `frms-coe-lib`, `frms-coe-startup-lib`, `auth-lib`, `auth-lib-provider-keycloak`, `rule-901`, `rule-902`, `tcs-lib`, `relay-service-integration-nats`, `relay-service-integration-rest`, `relay-service-integration-kafka`, `relay-service-integration-rabbitmq`, `audit-lib`.

> **frmscoe rule repos are not in this list.** They are managed by [`frmscoe/workflows`](https://github.com/frmscoe/workflows), which syncs to 33 rule repos (`rule-001` through `rule-091`, active subset) via its own `sync-workflows.yml` triggered on `push: dev`.

---

## Routine Maintenance

### Pinned action SHA updates

Most workflow files pin external actions to commit SHAs for supply-chain security. Rotate these quarterly or when a Dependabot alert is raised.

1. Find the new SHA on the action's GitHub releases page.
2. Update the SHA in the canonical file in `.github/workflows/`.
3. Update the SHA in the corresponding `workflow-docs/<file>.md` Dependencies table.
4. Open a PR to `dev`; sync will propagate the change to all target repos on merge.

### Node.js version updates

`node.js.yml` is not synced and must be updated in each repo individually.

1. Update the canonical `.github/workflows/node.js.yml` in this repo.
2. Apply the same change to each repo in `REPOS`, to `frmscoe/workflows`, and its 33 target repos.
3. Track progress in `update-workflows.md` (private planning doc, not committed to this repo).

### gh CLI version

The `gh` CLI in `sync-workflows.yml` is pinned to a hardcoded tarball URL. To update:

1. Find the new release tarball URL at <https://github.com/cli/cli/releases>.
2. Update the `curl` URL and the `tar`/`cp` filenames in the `Install GitHub CLI` step.

### Publishing an rc package manually

To publish a library rc without waiting for a push event:

1. Go to **Actions → Publish npm package** in the target library repo.
2. Click **Run workflow** from the `dev` branch.

### Running release-train

1. Go to **Actions → Release train** in the target library repo.
2. Click **Run workflow** from the `dev` branch; supply the target stable version (e.g. `4.0.0`, no prerelease suffix).
3. The workflow sets `version` to the supplied value, resolves all internal rc dependencies to their stable equivalents, regenerates `package-lock.json`, commits everything via the GitHub API, and opens a `release/vX.Y.Z → main` PR automatically.
4. Review the dependency changes and version bump in the PR, then merge. `publish.yml` fires automatically on the push to `main`.

### Creating a release (service repos)

1. Merge all changes to `main`.
2. Go to **Actions → Milestone Workflow** in the service repo.
3. Click **Run workflow** and enter the milestone ID.
4. `milestone.yml` closes the milestone and fires `release.yml` via `repository_dispatch`, which creates the GitHub release with an auto-generated changelog as the release body (no `CHANGELOG.md` or `VERSION` files are written to the repository).

### OSSF Scorecard

`scorecard.yml` runs automatically on `push` and on a weekly schedule. To trigger it manually:

1. Go to **Actions → Scorecard supply-chain security** in the target service repo.
2. Click **Run workflow**.

Results appear in **Security → Code scanning** only when triggered from `main`, a schedule, or a `branch_protection_rule` event.

### Auditing sync coverage

To verify all target repos reflect the latest canonical workflows:

1. Go to **Actions → Sync Workflows** in this repo.
2. Click **Run workflow** (`workflow_dispatch`) from `dev`.
3. Review the `sync-workflows-update` PRs opened in each target repo.

### Updating frmscoe/workflows

There is no automated mirror between this repo and `frmscoe/workflows`. After merging workflow changes to `dev` here, open a corresponding PR in [`frmscoe/workflows`](https://github.com/frmscoe/workflows) with the same changes, referencing the source PR.

---

## Known Issues

Active bugs where workflow behaviour differs from expectation. See the [issues tab](https://github.com/tazama-lf/workflows/issues) for the full list and status.

| Issue | Affected workflow(s) | Reference |
|-------|---------------------|-----------|
| `sync-workflows.yml` fires on all PR events to `dev`, not only on merge — do not merge sync PRs in target repos until the source PR here is confirmed merged | `sync-workflows.yml` | [#36](https://github.com/tazama-lf/workflows/issues/36) |
| `dco-check.yml` uses a reversed `git log` range — DCO sign-off is not being verified on the actual PR commits | `dco-check.yml` | [#37](https://github.com/tazama-lf/workflows/issues/37) |
| Codacy CLI crashes with `MalformedInputException` on checkov output from multi-line YAML files — workaround: add `.checkov.yaml` with `skip-framework: github_actions` at the repo root | `codacy.yml` | [#38](https://github.com/tazama-lf/workflows/issues/38) |
| `sbom.yml` is synced to library and rule repos but runs `docker build`, which fails in repos without a `Dockerfile` | `sbom.yml` | [#39](https://github.com/tazama-lf/workflows/issues/39) |
| `milestone.yml` and `release.yml` use the deprecated `::set-output` syntax and `actions/checkout@v2` | `milestone.yml`, `release.yml` | [#40](https://github.com/tazama-lf/workflows/issues/40) |
| Service repo clone URLs in `sync-workflows.yml` still use the `frmscoe` org — full migration to `tazama-lf` is pending | `sync-workflows.yml` | [#28](https://github.com/tazama-lf/workflows/issues/28) |
