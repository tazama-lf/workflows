# `node.js.yml`

## Purpose

Caller stub that delegates Node.js CI to the centralised reusable workflow [`node-ci.yml`](node-ci.md). Contains only the push/PR triggers and a single `uses:` reference - no logic lives here. This file is synced to all consumer repos unchanged.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[dev, main]` |
| `pull_request` | branches: `[dev, main]` |

---

## Execution Context

All execution context is defined in [`node-ci.yml`](node-ci.md). This stub adds no jobs, steps, or environment variables of its own.

---

## Jobs

### `node-ci`

Delegates entirely to the reusable workflow:

```yaml
uses: tazama-lf/workflows/.github/workflows/node-ci.yml@dev
secrets: inherit
```

See [`node-ci.yml` documentation](node-ci.md) for the full job breakdown.

---

## Required Secrets

All secrets are passed through via `secrets: inherit`. See [`node-ci.yml`](node-ci.md) for the list.

---

## Permissions

| Scope | Level |
|-------|-------|
| `contents` | `read` |

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| **All repos** | Synced - identical stub distributed to all 32 consumer repos |

Because the stub is static (it always points to `@dev`), subsequent syncs will skip repos where the file is already up to date.

---

## Dependencies (pinned actions)

None - this file contains no `uses:` action steps, only the reusable workflow reference.

---

## Known Limitations / Notes

- Logic changes belong in [`node-ci.yml`](node-ci.md), not here.
- `dependabot[bot]` actor exclusions are enforced inside `node-ci.yml`.
- The stub is identical across all consumer repos; repo-specific CI behaviour is not supported under this pattern. If a repo genuinely needs different CI behaviour it should maintain its own workflow and opt out of the sync for that file.
