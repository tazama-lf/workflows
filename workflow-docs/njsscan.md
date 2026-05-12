# `njsscan.yml`

## Purpose

Caller stub that delegates njsscan security scanning to the centralised reusable workflow [`njsscan-ci.yml`](njsscan-ci.md). Contains only the push/PR/schedule triggers and a single `uses:` reference - no logic lives here. This file is synced to all consumer repos unchanged.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[dev, main]` |
| `pull_request` | branches: `[dev, main]` |
| `schedule` | `17 17 * * 1` (Monday 17:17 UTC) |

---

## Execution Context

All execution context is defined in [`njsscan-ci.yml`](njsscan-ci.md). This stub adds no jobs, steps, or environment variables of its own.

---

## Jobs

### `njsscan`

Delegates entirely to the reusable workflow:

```yaml
uses: tazama-lf/workflows/.github/workflows/njsscan-ci.yml@dev
secrets: inherit
```

See [`njsscan-ci.yml` documentation](njsscan-ci.md) for the full job breakdown.

---

## Required Secrets

None. `secrets: inherit` is passed as a formality; the reusable workflow uses only `GITHUB_TOKEN`.

---

## Permissions

| Scope | Level |
|-------|-------|
| `contents` | `read` |
| `security-events` | `write` |
| `actions` | `read` |

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| All `REPOS` | Receives this file |

Because the stub is static (it always points to `@dev`), subsequent syncs will skip repos where the file is already up to date.
