# `conventional-commits.yml`

## Purpose

Caller stub that delegates PR title validation logic to the centralised reusable workflow [`conventional-commits-ci.yml`](conventional-commits-ci.md). Contains only the `pull_request` trigger and a single `uses:` reference - no logic lives here. This file is synced to all consumer repos unchanged.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `pull_request` | types: `[opened, synchronize, reopened, edited]` |

---

## Execution Context

All execution context is defined in [`conventional-commits-ci.yml`](conventional-commits-ci.md). This stub adds no jobs, steps, or environment variables of its own.

---

## Jobs

### `validate-pr-title`

Delegates entirely to the reusable workflow:

```yaml
uses: tazama-lf/workflows/.github/workflows/conventional-commits-ci.yml@dev
secrets: inherit
```

See [`conventional-commits-ci.yml` documentation](conventional-commits-ci.md) for the full job breakdown.

---

## Required Secrets

All secrets are passed through via `secrets: inherit`. See [`conventional-commits-ci.yml`](conventional-commits-ci.md) for the list.

---

## Permissions

| Scope | Level |
|-------|-------|
| `contents` | `read` |
| `pull-requests` | `write` |
| `issues` | `write` |

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| All `REPOS` | Receives this file |

Because the stub is static (it always points to `@dev`), subsequent syncs will skip repos where the file is already up to date.

## Known Limitations / Notes

- `dependabot[bot]` actors are excluded.
- GitHub labels must exist in the target repo before the action can apply them; the action will silently skip label creation if they are missing.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
