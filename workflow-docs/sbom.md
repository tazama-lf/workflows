# `sbom.yml`

## Purpose

Generates a Software Bill of Materials (SBOM) for the Docker image using Anchore Syft and uploads the results to the GitHub Dependency Submission API, enabling dependency tracking and vulnerability alerting in the GitHub Security tab.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[main]` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~3–5 min |
| Concurrency | none |
| Permissions | `contents: write` |

---

## Jobs

### `Anchore-Build-Scan`

**Steps:**

1. `actions/checkout@v4` — checks out source
2. `docker build . --file Dockerfile --tag localbuild/testimage:latest` — builds the Docker image locally
3. `anchore/sbom-action@bb716408e75840bbb01e839347cd213767269d4a` — scans the image; outputs `image.spdx.json` artifact; submits dependency snapshot to GitHub via Dependency Submission API

---

## Required Secrets

None.

---

## Sync Distribution

| Group | Behaviour |
|-------|-----------|
| All `REPOS` | Receives this file |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | tag ref `v4` | — |
| `anchore/sbom-action` | `bb716408e75840bbb01e839347cd213767269d4a` | — |

---

## Known Limitations / Notes

- `dependabot[bot]` actors are excluded.
- Synced to all repos including library repos that have no `Dockerfile`; the `docker build` step will fail in those repos. Consider excluding library repos (`PUBLISH_REPOS`) from receiving this file — tracked in tazama-lf/workflows#35.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
