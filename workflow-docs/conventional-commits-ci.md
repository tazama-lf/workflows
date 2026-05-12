# `conventional-commits-ci.yml`

## Purpose

Centralised reusable workflow that validates PR titles against the Conventional Commits specification. Called by the [`conventional-commits.yml`](conventional-commits.md) caller stub in every consumer repo. **Not synced to consumer repos.**

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by `conventional-commits.yml` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | < 30 s |
| Concurrency | none |
| Permissions | `pull-requests: write`, `issues: write` |

---

## Jobs

### `validate-pr-title`

**Skip condition:** actor is `dependabot[bot]` or `dependabot-preview[bot]`

**Steps:**

1. `ytanikin/PRConventionalCommits@b7be9213c4fa33260646db6c9b905332dc90b310` (1.1.0) - validates the PR title against the allowed type list; posts a comment if the title is non-conformant

**Configuration:**

```yaml
task_types: 'feat,fix,docs,style,refactor,perf,test,build,ci,feat!'
custom_labels:
  feat: feature
  fix: bug
  docs: documentation
  style: style
  refactor: refactoring
  perf: performance
  test: test
  build: build
  ci: CI
  feat!: breaking-change
```

---

## Required Secrets

None. Uses the inherited `GITHUB_TOKEN` for posting PR comments.

---

## Permissions

| Scope | Level |
|-------|-------|
| `pull-requests` | `write` |
| `issues` | `write` |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `ytanikin/PRConventionalCommits` | `b7be9213c4fa33260646db6c9b905332dc90b310` | 1.1.0 |
