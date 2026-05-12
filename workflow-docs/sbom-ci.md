# `sbom-ci.yml`

## Purpose

Centralised reusable workflow that builds the Docker image and generates a Software Bill of Materials (SBOM) using Anchore Syft, submitting the dependency snapshot to the GitHub Dependency Submission API. Called by the [`sbom.yml`](sbom.md) caller stub in every consumer repo. **Not synced to consumer repos.**

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by `sbom.yml` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~3-5 min |
| Concurrency | none |
| Permissions | `contents: write`, `actions: read` |

---

## Jobs

### `sbom`

**Steps:**

1. `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5` (v4) - checks out source
2. `Build Docker image` - `docker build . --file Dockerfile --tag localbuild/testimage:latest --secret id=GH_TOKEN,env=GH_TOKEN`; passes `GH_TOKEN_LIB` secret as `GH_TOKEN` build secret for private npm registry authentication; guarded by `if: hashFiles('Dockerfile') != ''`
3. `anchore/sbom-action@bb716408e75840bbb01e839347cd213767269d4a` - scans the local image; outputs `image.spdx.json` artifact; submits dependency snapshot to GitHub Dependency Submission API; guarded by `if: hashFiles('Dockerfile') != ''`

---

## Required Secrets

| Secret | Required | Purpose |
|--------|----------|---------|
| `GH_TOKEN_LIB` | Yes | Docker build-time authentication for pulling private npm packages from GitHub Packages |

---

## Permissions

| Scope | Level |
|-------|-------|
| `contents` | `write` |
| `actions` | `read` |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | `34e114876b0b11c390a56381ad16ebd13914f8d5` | v4 |
| `anchore/sbom-action` | `bb716408e75840bbb01e839347cd213767269d4a` | - |

---

## Known Limitations / Notes

- Both steps are guarded by `hashFiles('Dockerfile') != ''` so they are skipped cleanly in repos without a Dockerfile.
- Coverage for multi-image repos (where more than one Dockerfile exists) is tracked in [#81](https://github.com/tazama-lf/workflows/issues/81).
