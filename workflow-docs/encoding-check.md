# `encoding-check.yml`

## Purpose

Caller stub that delegates BOM/encoding check logic to the centralised reusable workflow [`encoding-check-ci.yml`](encoding-check-ci.md). Contains only the `pull_request` trigger and a single `uses:` reference - no logic lives here. This file is synced to all consumer repos unchanged.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `pull_request` | types: `[opened, synchronize, reopened]` |

---

## Execution Context

All execution context is defined in [`encoding-check-ci.yml`](encoding-check-ci.md). This stub adds no jobs, steps, or environment variables of its own.

---

## Jobs

### `encoding-check`

Delegates entirely to the reusable workflow:

```yaml
uses: tazama-lf/workflows/.github/workflows/encoding-check-ci.yml@dev
secrets: inherit
```

See [`encoding-check-ci.yml` documentation](encoding-check-ci.md) for the full job breakdown.

---

## Required Secrets

None. `secrets: inherit` is passed as a formality; the reusable workflow uses only `GITHUB_TOKEN`.

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