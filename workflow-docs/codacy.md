# `codacy.yml`

## Purpose

Caller stub that delegates Codacy Security Scan logic to the centralised reusable workflow [`codacy-ci.yml`](codacy-ci.md). Contains only the push/PR/schedule triggers and a single `uses:` reference - no logic lives here. This file is synced to all consumer repos unchanged.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[dev, main]` |
| `pull_request` | branches: `[dev, main]` |
| `schedule` | `17 0 * * 4` (Thursday 00:17 UTC) |

---

## Execution Context

All execution context is defined in [`codacy-ci.yml`](codacy-ci.md). This stub adds no jobs, steps, or environment variables of its own.

---

## Jobs

### `codacy-security-scan`

Delegates entirely to the reusable workflow:

```yaml
uses: tazama-lf/workflows/.github/workflows/codacy-ci.yml@dev
secrets: inherit
```

See [`codacy-ci.yml` documentation](codacy-ci.md) for the full job breakdown.

---

## Required Secrets

All secrets are passed through via `secrets: inherit`. See [`codacy-ci.yml`](codacy-ci.md) for the list.

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
