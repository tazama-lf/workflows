# `scorecard.yml`

## Purpose

Runs the OSSF Scorecard supply-chain security analysis to assess repository security practices (branch protection, dependency pinning, code review requirements, etc.) and publishes results to the OSSF Scorecard badge API and GitHub Advanced Security code scanning.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[main, dev]` |
| `schedule` | `15 16 * * 0` (Sunday 16:15 UTC) |
| `branch_protection_rule` | any change to branch protection rules |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~2–3 min |
| Concurrency | none |
| Permissions (workflow) | `read-all` |
| Permissions (job) | `security-events: write`, `id-token: write` |

---

## Jobs

### `analysis` — Scorecard analysis

**Steps:**

1. `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` — checks out source (`persist-credentials: false`)
2. `ossf/scorecard-action@4eaacf0543bb3f2c246792bd56e8cdeffafb205a` — runs analysis; outputs `results.sarif`; `publish_results=true` only on `main`, `schedule`, or `branch_protection_rule` events — dev-branch runs score the repo but do not overwrite the published badge
3. `actions/upload-artifact@bbbca2ddaa5d8feaa63e36b76fdaad77386f024f` — uploads `results.sarif` artifact (5-day retention)
4. `github/codeql-action/upload-sarif@38697555549f1db7851b81482ff19f1fa5c4fedc` — uploads SARIF to code scanning dashboard

---

## Required Secrets

None (uses GitHub OIDC token via `id-token: write`).

---

## Sync Distribution

| Group | Behaviour |
|-------|-----------|
| Service repos (`REPOS` minus `PUBLISH_REPOS`) | Receives this file |
| `PUBLISH_REPOS` | **Excluded** — scorecard is scoped to service repos only |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | `de0fac2e4500dabe0009e67214ff5f5447ce83dd` | v6.0.2 |
| `ossf/scorecard-action` | `4eaacf0543bb3f2c246792bd56e8cdeffafb205a` | v2.4.3 |
| `actions/upload-artifact` | `bbbca2ddaa5d8feaa63e36b76fdaad77386f024f` | v7.0.0 |
| `github/codeql-action/upload-sarif` | `38697555549f1db7851b81482ff19f1fa5c4fedc` | v4.34.1 |

---

## Known Limitations / Notes

- Scorecard enforces strict constraints: no workflow-level `env` or `defaults`; workflow permissions must be `read-all`; `id-token: write` is only permitted at job level.
- `publish_results` is intentionally `false` on `dev` branch pushes — the public badge and REST API always reflect the default branch score only.
- Depends on tazama-lf/technical-steering-committee#14 (default branch switch from `dev` to `main`) for the OSSF badge to display the correct score.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced service repos use the canonical version)_ |
