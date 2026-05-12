<!-- SPDX-License-Identifier: Apache-2.0 -->

# tazama-lf/workflows

Canonical GitHub Actions workflows for the Tazama project. This repository is the **single source of truth** for CI/CD automation across all active Tazama repositories in both the `tazama-lf` and `frmscoe` organisations.

Workflow files are distributed to target repositories automatically by [`sync-workflows.yml`](.github/workflows/sync-workflows.yml) on every pull request to `dev` in this repo. The `frmscoe/workflows` repo is a manually-maintained mirror of the relevant subset of files for `frmscoe` rule repos, seeded from this repo.

For detailed documentation on any individual workflow, see the [`workflow-docs/`](workflow-docs/) directory. A template for new entries is at [`workflow-docs/docs-template.md`](workflow-docs/docs-template.md).

---

## Table of Contents

- [Repository Classes](#repository-classes)
- [Standard PR Check Suite](#standard-pr-check-suite)
- [SDLC Flows](#sdlc-flows)
  - [1. Library repos (PUBLISH\_REPOS)](#1-library-repos-publish_repos)
  - [2. Service repos (Docker-building)](#2-service-repos-docker-building)
  - [3. Dual-container service repos](#3-dual-container-service-repos-case-management-system-connection-studio-rule-studio)
  - [4. Other service repos (no Docker CI build)](#4-other-service-repos-no-docker-ci-build)
  - [5. Rule repos - tazama-lf](#5-rule-repos---tazama-lf-rule-901-rule-902)
  - [6. Rule repos - frmscoe](#6-rule-repos---frmscoe-rule-001-through-rule-091)
  - [7. Multi-image service repos (biar)](#7-multi-image-service-repos-biar)
  - [8. Canonical workflow changes (this repo)](#8-canonical-workflow-changes-this-repo)
- [Canonical Workflow Reference](#canonical-workflow-reference)
- [Sync Distribution](#sync-distribution)
- [Adding Automation to a New Repository](#adding-automation-to-a-new-repository)
  - [Step 1 - Determine the repository class](#step-1---determine-the-repository-class)
  - [Step 2 - Add the repo to sync-workflows.yml](#step-2---add-the-repo-to-sync-workflowsyml-in-this-repo)
  - [Step 3 - Bootstrap the new repo's workflow directory](#step-3---bootstrap-the-new-repos-workflow-directory)
  - [Step 4 - Open a PR to dev in this repo](#step-4---open-a-pr-to-dev-in-this-repo)
  - [Step 5 - Update workflow-docs/](#step-5---update-workflow-docs)
- [Routine Maintenance](#routine-maintenance)
  - [Updating the library consumer catalog](#updating-the-library-consumer-catalog-library-consumersjson)
  - [Pinned action SHA updates](#pinned-action-sha-updates)
  - [Node.js version updates](#nodejs-version-updates)
  - [gh CLI version](#gh-cli-version)
  - [Publishing an rc package manually](#publishing-an-rc-package-manually)
  - [Running release-train](#running-release-train)
  - [Creating a release (service repos)](#creating-a-release-service-repos)
  - [OSSF Scorecard](#ossf-scorecard)
  - [Auditing sync coverage](#auditing-sync-coverage)
  - [Updating frmscoe/workflows](#updating-frmscoeworkflows)
- [Known Issues](#known-issues)
- [Frequently Asked Questions](#frequently-asked-questions)
  - [How do I run a specific workflow from the command line?](#how-do-i-run-a-specific-workflow-in-a-repo-at-a-specific-branch-from-the-command-line)

---

## Repository Classes

Each repository in the Tazama ecosystem belongs to one class. The class determines which workflows it receives, which SDLC path applies, and whether it builds Docker images, publishes npm packages, or both.

| Class | Repos | Output | Notes |
|-------|-------|--------|-------|
| **Service repos** | `auth-service`, `typology-processor`, `event-director`, `event-flow`, `event-sidecar`, `lumberjack`, `nats-utilities`, `batch-ppa`, `admin-service`, `tms-service`, `transaction-aggregation-decisioning-processor`, `data-enrichment-service`, `event-monitoring-service` | Docker image | Publish to Docker Hub; receive full workflow set including Docker build workflows |
| **Dual-container service repos** | `case-management-system`, `connection-studio`, `rule-studio` | Docker images (backend + frontend) | Each repo produces two Docker images from `backend/` and `frontend/` subdirectories; in `SPECIFIC_REPOS` so do not receive the single-image `dockerhub-image-build*.yml`; use `dockerhub-image-build-dual*.yml` committed directly instead |
| **Other service repos** | `relay-service`, `rule-executer`, `Full-Stack-Docker-Tazama` | - | In `SPECIFIC_REPOS`; do not receive `dockerhub-image-build*.yml` |
| **Library repos** | `frms-coe-lib`, `frms-coe-startup-lib`, `auth-lib`, `auth-lib-provider-keycloak`, `tcs-lib`, `audit-lib`, `relay-service-integration-nats`, `relay-service-integration-rest`, `relay-service-integration-kafka`, `relay-service-integration-rabbitmq` | npm package | Publish to GitHub Packages under `@tazama-lf` scope |
| **Rule repos - tazama-lf** | `rule-901`, `rule-902` | Docker image + npm package | Also in `PUBLISH_REPOS`; use `package-rule*.yml` caller stubs for Docker builds |
| **Rule repos - frmscoe** | `rule-001` through `rule-091` (33 active repos) | Docker image | Managed via [`frmscoe/workflows`](https://github.com/frmscoe/workflows); receive Docker builds via `package-rule*.yml` caller stubs |
| **Multi-image service repos** | `biar` | Docker images (5) | Produces 5 Docker images from subdirectories (`automation-orchestrator/`, `datalakehouse-api/`, `JupyterHub/`, `unstructured-pipeline/`, `nifi/`); in `SPECIFIC_REPOS` so does not receive single-image `dockerhub-image-build*.yml`; uses its own `dockerhub-image-build-multi*.yml` committed directly; mixed Python + TypeScript codebase |
| **Workflow repos** | `tazama-lf/workflows` (this repo), `frmscoe/workflows` | - | Canonical; not synced to |

---

## Standard PR Check Suite

The following checks run automatically on pull requests across all repo classes. They are defined once here and referenced throughout the SDLC sections below.

| Workflow | What it checks |
|----------|---------------|
| `branch-target-check.yml` | PR base branch must be `dev` or `release/v*` when targeting `main` - **fires on PRs to `main` only** |
| `conventional-commits.yml` | PR title is validated against the [Conventional Commits](https://www.conventionalcommits.org/) specification |
| `dco-check.yml` | All commits carry a DCO `Signed-off-by` trailer - ⚠️ [known issue #37](https://github.com/tazama-lf/workflows/issues/37) |
| `gpg-verify.yml` | All commits are GPG-signed |
| `codacy.yml` | Caller stub; delegates to `codacy-ci.yml` - static analysis via Codacy CLI (ESLint, Semgrep); Docker tools disabled; SARIF runs merged by `jq` before upload - ⚠️ [known issue #38](https://github.com/tazama-lf/workflows/issues/38) |
| `codeql.yml` | GitHub CodeQL SAST security scan |
| `njsscan.yml` | Node.js-specific security scan (semgrep rules) |
| `dependency-review.yml` | Flags new dependencies with known CVEs or licence restrictions |
| `node.js.yml` | Build, lint, and test on Node 22 LTS - caller stub; delegates to `node-ci.yml` (synced to all repos) |

> Pre-commit tooling (local linting, formatting, commit-msg hooks) is developer-local and not managed here. See the project [contribution guide](https://github.com/tazama-lf/tazama-documentation) for local setup guidance.

---

## SDLC Flows

### 1. Library repos (PUBLISH_REPOS)

Library repos publish versioned npm packages under the `@tazama-lf` scope. They do not produce Docker images. The versioning cycle uses rc pre-releases on `dev` and promotes to a stable release on `main`.

#### Feature development → dev

1. **Developer** - develops changes on a feature branch.
2. **Developer - MANUAL** - bumps `version` in `package.json` to `X.Y.Z-rc.N`.
3. **Developer** - opens pull request targeting `dev`.
4. **AUTO** - [standard PR check suite](#standard-pr-check-suite) fires.
5. **Reviewer - MANUAL** - reviews, approves, merges PR to `dev`.
6. **AUTO** - `publish.yml` fires on `push: dev`; detects the `-rc` suffix; publishes the package to GitHub Packages under the `rc` dist-tag.
7. **AUTO** - `library-dependency-rollout.yml` fires on `push: dev` (path: `package.json`); updates the exact version pin in every registered consumer repo's `package.json`, regenerates `package-lock.json`, commits to `dep/library-dependency-bump`, and opens (or updates) a `dep/library-dependency-bump → dev` PR in each consumer. If a PR already exists from a prior library bump it is reused - multiple library updates coalesce into a single open PR per consumer.

#### Release → main

1. **Developer - MANUAL** - triggers `release-train.yml` via `workflow_dispatch` from `dev`; enters the target stable version (e.g. `4.0.0`, no prerelease suffix).
2. **AUTO** - `release-train.yml` resolves all `-rc.*` dependencies to their stable equivalents, regenerates `package-lock.json`, and opens a `release/vX.Y.Z → main` PR. Fails if any dependency has no stable release yet.
3. **Developer - MANUAL** - in the release PR branch, strips the `-rc.N` suffix from `version` in `package.json`.
4. **AUTO** - `version-check.yml` fires on the PR targeting `main`; blocks merge if the version still contains a prerelease suffix.
5. **AUTO** - full standard PR check suite also fires on the `main`-targeting PR.
6. **Reviewer - MANUAL** - reviews and merges the release PR to `main`.
7. **AUTO** - `publish.yml` fires on `push: main`; detects a clean semver; publishes the package under the `latest` dist-tag.

---

### 2. Service repos (Docker-building)

Service repos produce versioned Docker images. They do not publish npm packages.

#### Feature development → dev

1. **Developer - MANUAL** - updates library dependency versions in `package.json` to consume any new rc or stable library releases (this step follows the [library release cycle](#1-library-repos-publish_repos) upstream).
2. **Developer** - develops changes on a feature branch.
3. **Developer** - opens pull request targeting `dev`.
4. **AUTO** - [standard PR check suite](#standard-pr-check-suite) fires, plus `dockerfile-linter.yml` if a `Dockerfile` was modified.
5. **Reviewer - MANUAL** - reviews, approves, merges PR to `dev`.
6. **AUTO** - `dockerhub-image-build-rc.yml` fires on `push: dev`; builds and pushes the Docker image tagged `:rc` to Docker Hub.
7. **AUTO** - `scorecard.yml` fires on `push: dev`; runs OSSF supply-chain checks (results published to the Security tab only on `main`, schedule, and `branch_protection_rule` triggers).

#### Release → main

1. **Developer** - opens pull request `dev → main`.
2. **AUTO** - standard PR check suite fires.
3. **Reviewer - MANUAL** - reviews, approves, merges to `main`.
4. **AUTO** - `dockerhub-image-build.yml` fires on `push: main`; reads `version` from `package.json`; builds and pushes the Docker image tagged `:X.Y.Z` to Docker Hub.
5. **AUTO** - `sbom.yml` fires on `push: main`; generates a Software Bill of Materials from the Docker image - ⚠️ [known issue #39](https://github.com/tazama-lf/workflows/issues/39).
6. **Release manager - MANUAL** - triggers `milestone.yml` via `workflow_dispatch` in the service repo, supplying the milestone ID.
7. **AUTO** - `milestone.yml` closes the milestone and fires `release.yml` via `repository_dispatch`.
8. **AUTO** - `release.yml` determines the version bump from commit messages, generates a changelog from merged PRs, and creates the GitHub release with the changelog as the release body (no `CHANGELOG.md` or `VERSION` files are written to the repository) - ⚠️ [known issue #40](https://github.com/tazama-lf/workflows/issues/40).

---

### 3. Dual-container service repos (case-management-system, connection-studio, rule-studio)

These repos follow the same PR check and release flow as standard Docker-building service repos, but each repo produces **two** Docker images - one from `backend/` and one from `frontend/` - independently versioned via their respective `package.json` files.

They are listed in both `REPOS` (to receive all common workflows) and `SPECIFIC_REPOS` (to suppress the single-image `dockerhub-image-build*.yml`). The dual-image Docker workflows are **not distributed via sync** and must be committed directly to each repo:

- `dockerhub-image-build-dual-rc.yml` - fires on `push: dev`; builds and pushes `tazamaorg/<repo>-backend:rc` and `tazamaorg/<repo>-frontend:rc`
- `dockerhub-image-build-dual.yml` - fires on `push: main`; builds and pushes `tazamaorg/<repo>-backend:<version>` and `tazamaorg/<repo>-frontend:<version>`

All other steps (PR checks, `sbom.yml`, `scorecard.yml`, `release.yml`, etc.) are identical to [Section 2](#2-service-repos-docker-building).

---

### 4. Other service repos (no Docker CI build)

`relay-service`, `rule-executer`, and `Full-Stack-Docker-Tazama` follow the same feature development and PR check flow as Docker-building service repos but do **not** receive `dockerhub-image-build*.yml` or `sbom.yml`. Their build and release processes (if any) are managed outside this workflow set.

---

### 5. Rule repos - tazama-lf (rule-901, rule-902)

tazama-lf rule repos are both library repos **and** Docker image producers. They follow the full library release cycle for npm publishing (including `release-train.yml`, `publish.yml`, and `version-check.yml`) and additionally build Docker images via the `package-rule*.yml` reusable workflows.

1. **Merged to `dev`** - same as library repos: `publish.yml` fires and publishes the rc npm package.
2. **AUTO** - `package-rule-rc.yml` caller stub fires on `push: dev`; calls the reusable workflow at `tazama-lf/workflows/.github/workflows/package-rule-rc.yml@dev`; builds and pushes the Docker image tagged `:rc`.
3. **Release to `main`** - same as library repos: `release-train.yml` resolves deps, opens release PR, `version-check.yml` guards the merge.
4. **Merged to `main`** - `publish.yml` fires and publishes the stable npm package.
5. **AUTO** - `package-rule.yml` caller stub fires on `push: main`; calls the reusable workflow; builds and pushes Docker images tagged `:X.Y.Z` and `:latest`.

---

### 6. Rule repos - frmscoe (rule-001 through rule-091)

frmscoe rule repos reside in the `frmscoe` organisation and are managed by [`frmscoe/workflows`](https://github.com/frmscoe/workflows), which is a manually-maintained mirror of the relevant subset of workflows from this repo. frmscoe rule repos build Docker images via `package-rule*.yml` caller stubs (referencing `frmscoe/workflows` as the reusable workflow source) but do not use `dockerhub-image-build*.yml` or `dockerfile-linter.yml`.

**Workflows frmscoe rule repos receive:** `branch-target-check.yml`, `codacy.yml`, `codeql.yml`, `conventional-commits.yml`, `dco-check.yml`, `dependency-review.yml`, `gpg-verify.yml`, `milestone.yml`, `njsscan.yml`, `node.js.yml`, `package-rule-rc.yml` (caller stub), `package-rule.yml` (caller stub), `publish.yml`, `release-train.yml`, `release.yml`, `sbom.yml`, `scorecard.yml`, `version-check.yml`.

**Not received:** `dockerfile-linter.yml`, `dockerhub-image-build.yml`, `dockerhub-image-build-rc.yml`.

**Sync trigger in frmscoe/workflows:** `push: dev` (not `pull_request` - sync fires after merge, not on PR open).

#### SDLC

1. **Developer** - develops changes on a feature branch.
2. **Developer** - opens pull request targeting `dev`.
3. **AUTO** - [standard PR check suite](#standard-pr-check-suite) fires.
4. **Reviewer - MANUAL** - reviews, approves, merges to `dev`.
5. **AUTO** - `package-rule-rc.yml` caller stub fires on `push: dev`; builds and pushes the rule Docker image tagged `:rc`.
6. **Developer** - opens pull request `dev → main` for the release.
7. **AUTO** - standard PR check suite fires.
8. **Reviewer - MANUAL** - reviews, approves, merges to `main`.
9. **AUTO** - `package-rule.yml` caller stub fires on `push: main`; builds and pushes Docker images tagged `:X.Y.Z` and `:latest`.

---

### 7. Multi-image service repos (biar)

BIAR is a mixed Python (PySpark) + TypeScript codebase that produces **5 Docker images** from separate subdirectories. It follows the same PR check and release flow as standard Docker-building service repos, but uses custom multi-image Docker publish workflows instead of the single-image or dual-image variants.

It is listed in both `REPOS` (to receive all common workflows) and `SPECIFIC_REPOS` (to suppress the single-image `dockerhub-image-build*.yml`). The multi-image Docker workflows are **not distributed via sync** and must be committed directly to the repo:

- `dockerhub-image-build-multi-rc.yml` — fires on `push: dev`; builds and pushes 5 images tagged `:rc` to Docker Hub
- `dockerhub-image-build-multi.yml` — fires on `push: main`; builds and pushes 5 images tagged `:{version}` to Docker Hub

Image names follow the pattern `tazamaorg/biar-{service}:{tag}` (e.g. `tazamaorg/biar-automation-orchestrator:rc`).

The repo also maintains a custom `ci.yml` (unified TypeScript build/lint/test + Python linting + Docker build check) instead of the standard `node.js.yml`.

All other steps (PR checks, `scorecard.yml`, `release.yml`, etc.) are identical to [Section 2](#2-service-repos-docker-building).

> **Note:** The synced `sbom.yml` is a no-op for BIAR (no root-level `Dockerfile`). SBOM coverage for multi-image repos is tracked in [#81](https://github.com/tazama-lf/workflows/issues/81).

---

### 8. Canonical workflow changes (this repo)

Changes to this repo propagate to all 32 target repositories. This is the highest-impact SDLC path.

1. **DevOps** - modifies workflow files in `.github/workflows/`; updates the corresponding `workflow-docs/` entry.
2. **DevOps** - opens pull request targeting `dev`.
3. **AUTO** - standard PR check suite fires against this repo.
4. **Reviewer - MANUAL** - reviews and merges the source PR to `dev` in this repo.
5. **AUTO** - `sync-workflows.yml` fires on `push: dev`; opens `sync-workflows-update` PRs (targeting `dev`) and `sync-workflows-update-main` PRs (targeting `main`) in all 32 target repos. Both PRs carry `[skip ci]` in the commit message and PR title so that squash-merging suppresses all push-triggered workflows (CI, Docker builds) on the resulting commit in the target repo.
6. **Reviewers in target repos - MANUAL** - review and merge both the `sync-workflows-update → dev` and `sync-workflows-update-main → main` PRs in each target repo. Keeping `main` current ensures scheduled workflows (`scorecard.yml`, `codeql.yml`, `njsscan.yml`, etc.) always run against current stub files - GitHub's scheduler reads scheduled workflows from the default branch only.
7. **DevOps - MANUAL** - applies the same changes to [`frmscoe/workflows`](https://github.com/frmscoe/workflows) via a separate PR (no automated mirror exists between the two workflow repos).
8. **AUTO** - once merged to `dev` in `frmscoe/workflows`, its `sync-workflows.yml` fires on `push: dev` and distributes the changes to all 33 frmscoe rule repos.

---

## Canonical Workflow Reference

Triggers shown are in the context of the **target repo** where each workflow is installed and runs.

| Workflow file | Purpose | Trigger (in target repo) | Synced to |
|--------------|---------|--------------------------|-----------|
| `branch-target-check.yml` | Caller stub: delegates branch target enforcement to `branch-target-check-ci.yml` | `pull_request` | All repos |
| `branch-target-check-ci.yml` | Reusable: enforce `dev` or `release/v*` as PR base when targeting `main`; called by `branch-target-check.yml` | `workflow_call` | **Not synced** - stays in this repo; called at runtime via `@dev` ref |
| `codacy.yml` | Caller stub: delegates Codacy static analysis to `codacy-ci.yml` | `push`, `pull_request` | All repos |
| `codacy-ci.yml` | Reusable: Codacy CLI static analysis (ESLint, Semgrep); SARIF runs merged before upload; called by `codacy.yml` - ⚠️ [known issue #38](https://github.com/tazama-lf/workflows/issues/38) | `workflow_call` | **Not synced** - stays in this repo; called at runtime via `@dev` ref |
| `codeql.yml` | Caller stub: delegates CodeQL SAST to `codeql-ci.yml` | `push: [dev,main]`, `pull_request: [dev,main]`, schedule | All repos |
| `codeql-ci.yml` | Reusable: GitHub CodeQL SAST security scan; called by `codeql.yml` | `workflow_call` | **Not synced** - stays in this repo; called at runtime via `@dev` ref |
| `conventional-commits.yml` | Caller stub: delegates PR title validation to `conventional-commits-ci.yml` | `pull_request` | All repos |
| `conventional-commits-ci.yml` | Reusable: validate PR title against Conventional Commits spec and apply GitHub label; called by `conventional-commits.yml` | `workflow_call` | **Not synced** - stays in this repo; called at runtime via `@dev` ref |
| `dco-check.yml` | Caller stub: delegates DCO sign-off check to `dco-check-ci.yml` | `pull_request` | All repos |
| `dco-check-ci.yml` | Reusable: verify DCO `Signed-off-by` on every PR commit; called by `dco-check.yml` | `workflow_call` | **Not synced** - stays in this repo; called at runtime via `@dev` ref |
| `encoding-check.yml` | Caller stub: delegates BOM/encoding check to `encoding-check-ci.yml` | `pull_request` | All repos |
| `encoding-check-ci.yml` | Reusable: fail PR if any changed file is UTF-16 or UTF-8 BOM encoded; called by `encoding-check.yml` | `workflow_call` | **Not synced** - stays in this repo; called at runtime via `@dev` ref |
| `dependency-review.yml` | Caller stub: delegates dependency CVE/licence scan to `dependency-review-ci.yml` | `pull_request` | All repos |
| `dependency-review-ci.yml` | Reusable: scan new dependencies for CVEs and licence restrictions; called by `dependency-review.yml` | `workflow_call` | **Not synced** - stays in this repo; called at runtime via `@dev` ref |
| `dockerfile-linter.yml` | Caller stub: delegates Hadolint linting to `dockerfile-linter-ci.yml` | `push: [dev,main]`, `pull_request: [dev]`, schedule | All repos (no-op where no `Dockerfile` exists) |
| `dockerfile-linter-ci.yml` | Reusable: Hadolint Dockerfile lint with SARIF upload; called by `dockerfile-linter.yml` | `workflow_call` | **Not synced** - stays in this repo; called at runtime via `@dev` ref |
| `dockerhub-image-build-dual-rc.yml` | Build and push `:rc` Docker images for backend and frontend | `push: [dev]`, `workflow_dispatch` | **Not synced** - committed directly to dual-container repos only |
| `dockerhub-image-build-dual.yml` | Build and push versioned Docker images for backend and frontend | `push: [main]`, `release: [published]` | **Not synced** - committed directly to dual-container repos only |
| `dockerhub-image-build-rc.yml` | Build and push `:rc` Docker image | `push: [dev]` | Service repos only (not SPECIFIC_REPOS) |
| `dockerhub-image-build.yml` | Build and push versioned Docker image | `push: [main]` | Service repos only (not SPECIFIC_REPOS) |
| `gpg-verify.yml` | Caller stub: delegates commit signature verification to `gpg-verify-ci.yml` | `pull_request` | All repos |
| `gpg-verify-ci.yml` | Reusable: verify GPG/SSH signature on every PR commit via GitHub API; called by `gpg-verify.yml` | `workflow_call` | **Not synced** - stays in this repo; called at runtime via `@dev` ref |
| `milestone.yml` | Close a milestone and trigger `release.yml` | `workflow_dispatch` | All repos |
| `njsscan.yml` | Caller stub: delegates njsscan security scanning to `njsscan-ci.yml` | `push: [dev,main]`, `pull_request: [dev,main]`, schedule | All repos |
| `njsscan-ci.yml` | Reusable: njsscan Node.js security scan with SARIF upload; called by `njsscan.yml` | `workflow_call` | **Not synced** - stays in this repo; called at runtime via `@dev` ref |
| `node-ci.yml` | Reusable: Node 22 LTS CI: build, lint, test | `workflow_call` | **Not synced** - stays in this repo; called at runtime via `@dev` ref |
| `node.js.yml` | Caller stub: delegates Node 22 LTS CI to `node-ci.yml` | `push: [dev,main]`, `pull_request: [dev,main]` | All repos |
| `package-rule-rc.yml` | Reusable: build and push `:rc` Docker image for a rule processor | `workflow_call` | Not synced directly; caller stubs distributed to `RULE_REPOS` |
| `package-rule.yml` | Reusable: build and push `:latest`/`:X.Y.Z` Docker images for a rule processor | `workflow_call` | Not synced directly; caller stubs distributed to `RULE_REPOS` |
| `library-dependency-rollout.yml` | On rc version merge to `dev` in a library repo, update the exact version pin in every registered consumer's `package.json`, regenerate `package-lock.json`, and open (or update) a `dep/library-dependency-bump → dev` PR | `push: [dev]` (path: `package.json`), `workflow_dispatch` | `PUBLISH_REPOS` only |
| `publish.yml` | Publish npm package to GitHub Packages | `push: [main]`, `workflow_dispatch` | `PUBLISH_REPOS` only |
| `release-train.yml` | Resolve rc deps, prepare release PR, bump version | `workflow_dispatch` | `PUBLISH_REPOS` only |
| `release.yml` | Create GitHub release with auto-generated changelog as release body | `repository_dispatch: [release]` (from `milestone.yml`) | All repos |
| `sbom.yml` | Caller stub: delegates Anchore Syft SBOM scan to `sbom-ci.yml` | `push: [main]` | All repos - ⚠️ [known issue #39](https://github.com/tazama-lf/workflows/issues/39) |
| `sbom-ci.yml` | Reusable: build Docker image and generate Syft SBOM via Dependency Submission API; called by `sbom.yml` | `workflow_call` | **Not synced** - stays in this repo; called at runtime via `@dev` ref |
| `scorecard.yml` | OSSF Scorecard supply-chain security | `push: [main,dev]`, schedule (weekly), `branch_protection_rule` | Service repos only (not `PUBLISH_REPOS`) |
| `sync-workflows.yml` | Distribute canonical workflows to all target repos | `push: [dev]`, `workflow_dispatch` | **Not synced** - canonical-only |
| `version-check.yml` | Block PR to `main` if `package.json` version has a prerelease suffix | `pull_request: [main]` | `PUBLISH_REPOS` only |

---

## Sync Distribution

`sync-workflows.yml` uses four groups to control which workflows each target repo receives.

| Group | Members | Behaviour |
|-------|---------|-----------|
| `REPOS` | All 32 tazama-lf target repos | Receive all workflows except those explicitly excluded |
| `SPECIFIC_REPOS` | All library repos + `relay-service`, `rule-executer`, `Full-Stack-Docker-Tazama` + dual-container repos (`case-management-system`, `connection-studio`, `rule-studio`) + multi-image repos (`biar`) | Skip `dockerhub-image-build.yml`, `dockerhub-image-build-rc.yml`, `dockerhub-image-build-dual.yml`, `dockerhub-image-build-dual-rc.yml` |
| `PUBLISH_REPOS` | All library repos + `rule-901`, `rule-902` | Additionally receive `publish.yml`, `version-check.yml`, `release-train.yml`, `library-dependency-rollout.yml`; skip `scorecard.yml` |
| `RULE_REPOS` | `rule-901`, `rule-902` | Receive caller stubs for `package-rule*.yml` instead of the full reusable workflow definition |

**Always excluded from the sync bundle:**

| File | Reason |
|------|--------|
| `sync-workflows.yml` | Canonical-only; never distributed to target repos |
| `branch-target-check-ci.yml` | Reusable workflow; stays in this repo and is called by the `branch-target-check.yml` stub at runtime via `@dev` ref |
| `codacy-ci.yml` | Reusable workflow; stays in this repo and is called by the `codacy.yml` stub at runtime via `@dev` ref |
| `codeql-ci.yml` | Reusable workflow; stays in this repo and is called by the `codeql.yml` stub at runtime via `@dev` ref |
| `conventional-commits-ci.yml` | Reusable workflow; stays in this repo and is called by the `conventional-commits.yml` stub at runtime via `@dev` ref |
| `dco-check-ci.yml` | Reusable workflow; stays in this repo and is called by the `dco-check.yml` stub at runtime via `@dev` ref |
| `dependency-review-ci.yml` | Reusable workflow; stays in this repo and is called by the `dependency-review.yml` stub at runtime via `@dev` ref |
| `dockerfile-linter-ci.yml` | Reusable workflow; stays in this repo and is called by the `dockerfile-linter.yml` stub at runtime via `@dev` ref |
| `encoding-check-ci.yml` | Reusable workflow; stays in this repo and is called by the `encoding-check.yml` stub at runtime via `@dev` ref |
| `gpg-verify-ci.yml` | Reusable workflow; stays in this repo and is called by the `gpg-verify.yml` stub at runtime via `@dev` ref |
| `njsscan-ci.yml` | Reusable workflow; stays in this repo and is called by the `njsscan.yml` stub at runtime via `@dev` ref |
| `node-ci.yml` | Reusable workflow; stays in this repo and is called by the `node.js.yml` stub at runtime via `@dev` ref |
| `sbom-ci.yml` | Reusable workflow; stays in this repo and is called by the `sbom.yml` stub at runtime via `@dev` ref |

**Additionally distributed (not in `.github/workflows/`):**

| File | Destination in target repo | Reason |
|------|---------------------------|--------|
| `config-templates/.codacy.yml` | `.codacy.yml` (repo root) | Standard Codacy engine allowlist for TypeScript/Node.js repos; enables ESLint and Semgrep only, suppressing false positives from Python/Java engines |

**Workflow branch activation**

Not all workflows are equally active on `dev` and `main`. The table below categorizes installed workflows by which branch they perform meaningful work on in a typical target repo. This is the primary reason the sync targets both branches.

| Category | Workflows | Branch |
|----------|-----------|--------|
| **Scheduled security scans** - GitHub's scheduler reads from the default branch; stale `main` = broken or silently skipped scans | `scorecard.yml`, `codeql.yml` (schedule), `njsscan.yml` (schedule), `dockerfile-linter.yml` (schedule) | `main` required; also run on `dev` push |
| **Release artifact builds** - fire on push to `main` only | `dockerhub-image-build.yml`, `publish.yml`, `sbom.yml` | `main` only |
| **RC/dev artifact builds** - fire on push to `dev` only | `dockerhub-image-build-rc.yml`, `library-dependency-rollout.yml` | `dev` only |
| **Push CI** - fire on push to both branches | `node.js.yml`, `dockerfile-linter.yml` (push trigger), `codeql.yml` (push trigger), `njsscan.yml` (push trigger) | Both |
| **PR gate checks** - fire on pull request events only; physical branch location does not matter | `branch-target-check.yml`, `conventional-commits.yml`, `dco-check.yml`, `dependency-review.yml`, `encoding-check.yml`, `gpg-verify.yml`, `codacy.yml` | PR only |

**Full `REPOS` list (32 repos):** `relay-service`, `auth-service`, `typology-processor`, `event-director`, `event-sidecar`, `lumberjack`, `nats-utilities`, `batch-ppa`, `admin-service`, `tms-service`, `transaction-aggregation-decisioning-processor`, `Full-Stack-Docker-Tazama`, `rule-executer`, `event-flow`, `frms-coe-lib`, `frms-coe-startup-lib`, `auth-lib`, `auth-lib-provider-keycloak`, `rule-901`, `rule-902`, `tcs-lib`, `relay-service-integration-nats`, `relay-service-integration-rest`, `relay-service-integration-kafka`, `relay-service-integration-rabbitmq`, `audit-lib`, `data-enrichment-service`, `event-monitoring-service`, `case-management-system`, `connection-studio`, `rule-studio`, `biar`.

> **frmscoe rule repos are not in this list.** They are managed by [`frmscoe/workflows`](https://github.com/frmscoe/workflows), which syncs to 33 rule repos (`rule-001` through `rule-091`, active subset) via its own `sync-workflows.yml` triggered on `push: dev`.

> ⚠️ **`sync-workflows-update` is a reserved branch name.** This branch is created and managed by `sync-workflows.yml` in every target repo. Do not use this name for regular development contributions - the sync workflow will delete it and recreate it fresh from `dev` on every run. If you have an open `sync-workflows-update` branch in a target repo, be aware it will be force-replaced the next time the workflow runs.

> ⚠️ **`sync-workflows-update-main` is a reserved branch name.** This branch is created and managed by `sync-workflows.yml` alongside `sync-workflows-update`. It is always cut from `main` and its PR targets `main`. Do not use this name for regular development contributions - it will be force-replaced on every sync run.

> **Why sync targets both `dev` and `main`:** GitHub's job scheduler always reads scheduled workflow definitions from the repository's default branch (`main`). If `main` is stale, scheduled scans like `scorecard.yml`, `codeql.yml`, and `njsscan.yml` run against outdated or missing stub files. Syncing to `main` ensures scheduled workflows always have current definitions regardless of what triggered the run.

> ⚠️ **`dep/library-dependency-bump` is a reserved branch name.** This branch is created and managed by `library-dependency-rollout.yml` in every consumer repo. Do not use this name for regular development contributions. Multiple library bumps coalesce onto this branch - the workflow pushes new commits onto an existing branch rather than creating a new one.

---

## Adding Automation to a New Repository

When a new repository is created in the Tazama ecosystem, it needs to be enrolled in sync so it receives canonical workflows automatically on future updates. The steps depend on the [repository class](#repository-classes).

### Step 1 - Determine the repository class

| Class | Receives Docker build workflows? | Receives `publish.yml` / `version-check.yml` / `release-train.yml` / `library-dependency-rollout.yml`? |
|-------|----------------------------------|----------------------------------------------------------------------------------------------------------|
| Service repo (Docker-building) | ✅ Yes | ❌ No |
| Dual-container service repo | ❌ No (add to `SPECIFIC_REPOS`) | ❌ No |
| Multi-image service repo (biar) | ❌ No (add to `SPECIFIC_REPOS`) | ❌ No |
| Other service repo (no Docker build) | ❌ No (add to `SPECIFIC_REPOS`) | ❌ No |
| Library repo | ❌ No (add to `SPECIFIC_REPOS`) | ✅ Yes (add to `PUBLISH_REPOS`); also add entry to `library-consumers.json` if it will be consumed by other repos |
| Rule repo - tazama-lf | ❌ No (add to `SPECIFIC_REPOS` + `RULE_REPOS`) | ✅ Yes (add to `PUBLISH_REPOS`) |
| Rule repo - frmscoe | n/a - managed by [`frmscoe/workflows`](https://github.com/frmscoe/workflows) | n/a |

### Step 2 - Add the repo to `sync-workflows.yml` in this repo

Open `.github/workflows/sync-workflows.yml` and add the repo name to the appropriate `env` lists:

- **Always**: add to `REPOS`
- **Other service, dual-container, multi-image, library, or tazama-lf rule repo**: also add to `SPECIFIC_REPOS`
- **Library or tazama-lf rule repo**: also add to `PUBLISH_REPOS`
- **tazama-lf rule repo**: also add to `RULE_REPOS`

> Library repos (`PUBLISH_REPOS`) are cloned from `tazama-lf`; service repos are cloned from `frmscoe` (see [known issue #28](https://github.com/tazama-lf/workflows/issues/28) - full org migration pending).

### Step 3 - Bootstrap the new repo's workflow directory

`sync-workflows.yml` only runs against repos that already have a `.github/workflows/` directory. For a brand-new repo, copy the relevant workflows manually from this repo's `.github/workflows/` before raising the sync PR:

1. Create `.github/workflows/` in the new repo.
2. Copy all applicable workflow files (refer to the [Canonical Workflow Reference](#canonical-workflow-reference) table).
3. If it is a tazama-lf rule repo, stamp the caller stubs for `package-rule-rc.yml` and `package-rule.yml` (see the stub templates in [`sync-workflows.yml`](.github/workflows/sync-workflows.yml) under the `RULE_REPOS` block).
4. Commit directly to `dev` in the new repo (or raise a bootstrap PR).
5. Copy `node.js.yml` manually and customise it for the repo (it is never synced).

### Step 4 - Open a PR to `dev` in this repo

Raise a PR with the `sync-workflows.yml` changes from Step 2. When the PR is opened, `sync-workflows.yml` runs (due to the `pull_request: dev` trigger) and creates `sync-workflows-update` PRs in all existing repos - the new entry will be included.

> ⚠️ Do not merge the sync PRs in target repos until this source PR is confirmed merged - see [known issue #36](https://github.com/tazama-lf/workflows/issues/36).

### Step 5 - Update `workflow-docs/`

Add a documentation file for any new canonical workflow using [`workflow-docs/docs-template.md`](workflow-docs/docs-template.md) as a starting point, and update the [Canonical Workflow Reference](#canonical-workflow-reference) table and [Sync Distribution](#sync-distribution) section if the new repo changes group membership.

---

## Routine Maintenance

### Updating the library consumer catalog (`library-consumers.json`)

`library-consumers.json` at the root of this repo is the canonical list of which repos consume which `@tazama-lf/*` library packages. It drives `library-dependency-rollout.yml`. The catalog is fetched at runtime by the rollout workflow from `tazama-lf/workflows@dev` - no library repo stores or owns the consumer list.

**When to update:** when a new consumer repo is created, when a repo stops consuming a library, or when a new library is added.

> You only ever update this file in `tazama-lf/workflows`. You do not need to touch any library repo. The next time any library merges to `dev`, the rollout will automatically include the new consumer.

1. Optionally re-run your local copy of `audit-library-consumers.js` to regenerate the file from live data:

   ```bash
   node audit-library-consumers.js --token <gh-pat>
   ```
2. Review the output in `library-consumers.json`.
3. Open a PR to `dev` in this repo with the updated file.

Alternatively, edit `library-consumers.json` directly and open a PR.

---

### Pinned action SHA updates

Most workflow files pin external actions to commit SHAs for supply-chain security. Rotate these quarterly or when a Dependabot alert is raised.

1. Find the new SHA on the action's GitHub releases page.
2. Update the SHA in the canonical file in `.github/workflows/`.
3. Update the SHA in the corresponding `workflow-docs/<file>.md` Dependencies table.
4. Open a PR to `dev`; sync will propagate the change to all target repos on merge.

### Node.js version updates

`node-ci.yml` is the single place to update the Node.js version. It is **not synced** to target repos - it stays in this repo and is called at runtime via `@dev` ref by the `node.js.yml` caller stub in every target repo. Bumping the version here takes effect immediately on the next workflow run in all repos without requiring any sync PR.

1. Update `node-version:` in all three jobs (`build`, `lint`, `test`) in `.github/workflows/node-ci.yml`.
2. Update the step names (`Use Node.js XX`) to match.
3. Open a PR to `dev` in this repo.

### gh CLI version

The `gh` CLI in `sync-workflows.yml` is pinned to a hardcoded tarball URL. To update:

1. Find the new release tarball URL at <https://github.com/cli/cli/releases>.
2. Update the `curl` URL and the `tar`/`cp` filenames in the `Install GitHub CLI` step.

### Publishing an rc package manually

To publish a library rc without waiting for a push event:

1. Go to **Actions → Publish npm package to GitHub Packages** in the target library repo.
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

`scorecard.yml` runs automatically on `push` to `main` or `dev`, on a weekly schedule (`branch_protection_rule` events also trigger it). To trigger it manually:

1. Go to **Actions → Scorecard supply-chain security** in the target service repo.
2. Click **Run workflow**.

SARIF results always appear in **Security → Code scanning** regardless of trigger. The public Scorecard badge and REST API are only updated when triggered from `main`, a schedule, or a `branch_protection_rule` event (`publish_results=false` on `dev` pushes).

### Auditing sync coverage

To verify all target repos reflect the latest canonical workflows:

1. Go to **Actions → Sync Workflows** in this repo.
2. Click **Run workflow** (`workflow_dispatch`) from `dev`.
3. Review the `sync-workflows-update` PRs opened in each target repo.

### Updating frmscoe/workflows

There is no automated mirror between this repo and `frmscoe/workflows`. After merging workflow changes to `dev` here, open a corresponding PR in [`frmscoe/workflows`](https://github.com/frmscoe/workflows) with the same changes, referencing the source PR.

---

## Known Issues

See the [issues tab](https://github.com/tazama-lf/workflows/issues) for active bugs and tracked work.

---

## Frequently Asked Questions

### How do I run a specific workflow in a repo at a specific branch from the command line?

Use the `gh` CLI (works identically on Windows, macOS, and Linux):

```sh
gh workflow run <workflow-file> -R <owner>/<repo> --ref <branch>
```

**Example - trigger the Node.js CI workflow on `dev` in a library repo:**

By file:

```sh
gh workflow run node.js.yml -R tazama-lf/frms-coe-lib --ref dev
```

or, by name:

```sh
gh workflow run "Node.js CI" -R tazama-lf/frms-coe-lib --ref dev
```

**Example - trigger a workflow that has required inputs (`release-train.yml`):**

```sh
gh workflow run release-train.yml -R tazama-lf/frms-coe-lib --ref dev -f version=4.0.0
```

**Notes:**
- The workflow must have a `workflow_dispatch:` trigger - workflows without it cannot be triggered manually. Check the [Canonical Workflow Reference](#canonical-workflow-reference) table for the trigger column.
- `<workflow-file>` is the filename (e.g. `node.js.yml`) or the workflow's `name:` string as it appears in the Actions UI (e.g. `"Node.js CI"`).
- `--ref` must be a branch that exists in the target repo. To run against the canonical reusable workflows in this repo, use `--ref dev`.
- After triggering, check run status with: `gh run list -R <owner>/<repo> --workflow <workflow-file>`
