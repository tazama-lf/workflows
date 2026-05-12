# `sbom.yml`

## Purpose

Caller stub that delegates Anchore Syft SBOM generation to the centralised reusable workflow [`sbom-ci.yml`](sbom-ci.md). Contains only the `push: main` trigger and a single `uses:` reference - no logic lives here. This file is synced to all consumer repos unchanged.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[main]` |

---

## Execution Context

All execution context is defined in [`sbom-ci.yml`](sbom-ci.md). This stub adds no jobs, steps, or environment variables of its own.

---

## Jobs

### `sbom`

Delegates entirely to the reusable workflow:

```yaml
uses: tazama-lf/workflows/.github/workflows/sbom-ci.yml@dev
secrets: inherit
```

See [`sbom-ci.yml` documentation](sbom-ci.md) for the full job breakdown.

---

## Required Secrets

All secrets are passed through via `secrets: inherit`. `sbom-ci.yml` requires `GH_TOKEN_LIB` for Docker build authentication in repos that pull private npm packages.

---

## Permissions

| Scope | Level |
|-------|-------|
| `contents` | `write` |
| `actions` | `read` |

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| All `REPOS` | Receives this file - a no-op if the repo has no `Dockerfile` |

Because the stub is static (it always points to `@dev`), subsequent syncs will skip repos where the file is already up to date.

---

## Known Limitations / Notes

- Synced to all repos including library repos that have no `Dockerfile`; both steps guarded by `hashFiles('Dockerfile') != ''` so they are skipped cleanly. Coverage for multi-image repos is tracked in [#81](https://github.com/tazama-lf/workflows/issues/81).