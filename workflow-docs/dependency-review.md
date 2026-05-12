# `dependency-review.yml`

## Purpose

Caller stub that delegates dependency CVE/licence scanning to the centralised reusable workflow [`dependency-review-ci.yml`](dependency-review-ci.md). Contains only the `pull_request` trigger and a single `uses:` reference - no logic lives here. This file is synced to all consumer repos unchanged.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `pull_request` | all types |

---

## Execution Context

All execution context is defined in [`dependency-review-ci.yml`](dependency-review-ci.md). This stub adds no jobs, steps, or environment variables of its own.

---

## Jobs

### `dependency-review`

Delegates entirely to the reusable workflow:

```yaml
uses: tazama-lf/workflows/.github/workflows/dependency-review-ci.yml@dev
secrets: inherit
```

See [`dependency-review-ci.yml` documentation](dependency-review-ci.md) for the full job breakdown.

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
