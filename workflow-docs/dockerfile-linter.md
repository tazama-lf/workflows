# `dockerfile-linter.yml`

## Purpose

Caller stub that delegates Hadolint Dockerfile linting to the centralised reusable workflow [`dockerfile-linter-ci.yml`](dockerfile-linter-ci.md). Contains only the push/PR/schedule triggers and a single `uses:` reference - no logic lives here. This file is synced to all consumer repos unchanged.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[dev, main]` |
| `pull_request` | branches: `[dev]` |
| `schedule` | `17 13 * * 0` (Sunday 13:17 UTC) |

---

## Execution Context

All execution context is defined in [`dockerfile-linter-ci.yml`](dockerfile-linter-ci.md). This stub adds no jobs, steps, or environment variables of its own.

---

## Jobs

### `dockerfile-linter`

Delegates entirely to the reusable workflow:

```yaml
uses: tazama-lf/workflows/.github/workflows/dockerfile-linter-ci.yml@dev
secrets: inherit
```

See [`dockerfile-linter-ci.yml` documentation](dockerfile-linter-ci.md) for the full job breakdown.

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
| All `REPOS` | Receives this file - a no-op if the repo has no `Dockerfile` |

Because the stub is static (it always points to `@dev`), subsequent syncs will skip repos where the file is already up to date.
