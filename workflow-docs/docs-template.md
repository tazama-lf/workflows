# `<workflow-filename>.yml`

## Purpose

One or two sentences describing what this workflow does and why it exists.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[main, dev]` |
| `workflow_dispatch` | manual only |
| `schedule` | `0 4 * * 1` (weekly Monday 04:00 UTC) |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Node version | `20` |
| Typical duration | ~2 min |
| Concurrency | none / `cancel-in-progress: true` |
| Permissions | `contents: read`, `security-events: write` |

---

## Jobs

### `<job-id>` - <short description>

**Steps:**

1. `actions/checkout@<sha>` - checks out source
2. `<step name>` - <what it does>
3. ...

**Outputs:** _(if any)_

| Output | Set by step | Description |
|--------|------------|-------------|
| `VERSION` | `pkg_version` | Semver string from `package.json` |

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|---------|
| `GH_TOKEN` | repo | Clone and push to target repos |
| `DOCKERHUB_USERNAME` | org | Docker Hub login |

---

## Sync Distribution

| Group | Behaviour |
|-------|-----------|
| `REPOS` | Receives this file |
| `SPECIFIC_REPOS` | **Excluded** - reason |
| `PUBLISH_REPOS` | **Excluded** - reason |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | `11bd71901...` | `v4` |
| `docker/login-action` | `9ec57ed1f...` | `v3` |

---

## Known Limitations / Notes

- Bullet list of gotchas, edge cases, or deferred work items with issue links.

---

## Repository Overrides

Repos that maintain their own copy of this workflow instead of receiving it via sync, and the reason why:

| Repository | Reason |
|-----------|--------|
| `relay-service` | Custom multi-plugin Docker matrix (multiple images built per run); canonical single-image workflow cannot represent this |
| _(none)_ | _(all synced repos use the canonical version)_ |
