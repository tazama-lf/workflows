# `branch-target-check.yml`

## Purpose

Caller stub that delegates branch target enforcement logic to the centralised reusable workflow [`branch-target-check-ci.yml`](branch-target-check-ci.md). Contains only the `pull_request: branches: [main]` trigger and a single `uses:` reference - no logic lives here. This file is synced to all consumer repos unchanged.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `pull_request` | branches: `[main]` |

---

## Execution Context

All execution context is defined in [`branch-target-check-ci.yml`](branch-target-check-ci.md). This stub adds no jobs, steps, or environment variables of its own.

---

## Jobs

### `check-source-branch`

Delegates entirely to the reusable workflow:

```yaml
uses: tazama-lf/workflows/.github/workflows/branch-target-check-ci.yml@dev
secrets: inherit
```

See [`branch-target-check-ci.yml` documentation](branch-target-check-ci.md) for the full job breakdown.

---

## Required Secrets

None. `secrets: inherit` is passed as a formality; the reusable workflow uses only shell logic.

---

## Permissions

| Scope | Level |
|-------|-------|
| `contents` | `read` |

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| All `REPOS` | Receives this file |

Because the stub is static (it always points to `@dev`), subsequent syncs will skip repos where the file is already up to date.