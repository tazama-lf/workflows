#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# GitHub-native release orchestrator (single entry point).
# Walks ordered org-variable lists and triggers product-repo callers.
# Writes a Sync-Workflows-style PR summary to GITHUB_STEP_SUMMARY for PMs.
#
# Required env:
#   ORG              tazama-lf | frmscoe
#   RELEASE_TYPE     libs | services | rules | non-code | all
#   PLATFORM_VERSION e.g. 4.0.0 (or REL_VERSION)
#
# List source (order = kick-off order, left → right):
#   REL_LIBS / REL_SERVICES / REL_RULES / REL_NON_CODE
#
# Optional:
#   REL_PACKAGE_SCOPE, SOURCE_BRANCH, TARGET_BRANCH, WAIT_PUBLISH,
#   WAIT_WORKFLOW, DRY_RUN, REPO_FILTER, REL_WAIT_MERGE, GH_TOKEN

set -euo pipefail

ORG="${ORG:-}"
RELEASE_TYPE="${RELEASE_TYPE:-}"
PLATFORM_VERSION="${PLATFORM_VERSION:-${REL_VERSION:-}}"
SOURCE_BRANCH="${SOURCE_BRANCH:-${REL_SOURCE_BRANCH:-dev}}"
TARGET_BRANCH="${TARGET_BRANCH:-${REL_TARGET_BRANCH:-main}}"
WAIT_PUBLISH="${WAIT_PUBLISH:-${REL_WAIT_PUBLISH:-true}}"
WAIT_WORKFLOW="${WAIT_WORKFLOW:-true}"
DRY_RUN="${DRY_RUN:-${REL_DRY_RUN:-false}}"
REPO_FILTER="${REPO_FILTER:-}"
RUN_TIMEOUT="${RUN_TIMEOUT:-1800}"
PUBLISH_TIMEOUT="${PUBLISH_TIMEOUT:-7200}"
PUBLISH_POLL="${PUBLISH_POLL:-30}"
PACKAGE_SCOPE="${REL_PACKAGE_SCOPE:-}"

log() { printf '%s\n' "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }

truthy() {
  case "${1,,}" in
    true|1|yes|y) return 0 ;;
    *) return 1 ;;
  esac
}

need() {
  if [ -z "${!1:-}" ]; then
    err "$1 is required"
    exit 1
  fi
}

need ORG
need RELEASE_TYPE
need PLATFORM_VERSION

if [ -z "$PACKAGE_SCOPE" ]; then
  PACKAGE_SCOPE="@${ORG}"
fi

command -v gh >/dev/null || { err "gh CLI is required"; exit 1; }

types_to_run=()
case "$RELEASE_TYPE" in
  libs|services|rules|non-code)
    types_to_run=("$RELEASE_TYPE")
    ;;
  all)
    types_to_run=(libs services rules non-code)
    ;;
  *)
    err "RELEASE_TYPE must be libs|services|rules|non-code|all (got: $RELEASE_TYPE)"
    exit 1
    ;;
esac

# Accumulators for job summary (Sync Workflows style)
CREATED_PRS=()
EXISTING_PRS=()
FAILED_REPOS=()
SKIPPED_REPOS=()
DRY_RUN_REPOS=()

list_for_type() {
  case "$1" in
    libs) printf '%s' "${REL_LIBS:-}" ;;
    services) printf '%s' "${REL_SERVICES:-}" ;;
    rules) printf '%s' "${REL_RULES:-}" ;;
    non-code) printf '%s' "${REL_NON_CODE:-}" ;;
    *) printf '' ;;
  esac
}

caller_for_type() {
  case "$1" in
    non-code) printf 'dev-to-main-pr.yml' ;;
    *) printf 'release-train.yml' ;;
  esac
}

# Head branch used by the product-repo caller when opening the PR to main
pr_head_for_type() {
  case "$1" in
    non-code) printf '%s' "$SOURCE_BRANCH" ;;
    *) printf 'release/v%s' "$PLATFORM_VERSION" ;;
  esac
}

filter_list() {
  local raw="$1"
  local filter="$REPO_FILTER"
  local -a items=()
  local -a out=()
  local item

  IFS=',' read -r -a items <<< "$raw"
  for item in "${items[@]}"; do
    item="$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$item" ] && continue
    if [ -n "$filter" ]; then
      local ok=0
      local f
      IFS=',' read -r -a filt_arr <<< "$filter"
      for f in "${filt_arr[@]}"; do
        f="$(echo "$f" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        if [ "$f" = "$item" ]; then ok=1; break; fi
      done
      [ "$ok" -eq 1 ] || continue
    fi
    out+=("$item")
  done

  if [ "${#out[@]}" -eq 0 ]; then
    printf ''
    return 0
  fi
  local IFS=','
  printf '%s' "${out[*]}"
}

# Look up open PR opened by release-train / dev-to-main-pr
find_release_pr() {
  local full_repo="$1"
  local head="$2"
  local url=""

  url="$(gh pr list -R "$full_repo" \
    --head "$head" \
    --base "$TARGET_BRANCH" \
    --state open \
    --limit 1 \
    --json url \
    --jq '.[0].url // empty' 2>/dev/null || true)"

  if [ -z "$url" ]; then
    # Fall back: any state (may already be merged on re-run)
    url="$(gh pr list -R "$full_repo" \
      --head "$head" \
      --base "$TARGET_BRANCH" \
      --state all \
      --limit 1 \
      --json url \
      --jq '.[0].url // empty' 2>/dev/null || true)"
  fi

  printf '%s' "$url"
}

write_step_summary() {
  local summary_file="${GITHUB_STEP_SUMMARY:-}"
  if [ -z "$summary_file" ]; then
    log "(No GITHUB_STEP_SUMMARY - printing PR summary to log only)"
    summary_file="/dev/stdout"
  fi

  {
    echo "## Release orchestrator - PR Summary"
    echo ""
    echo "| | |"
    echo "|---|---|"
    echo "| **Org** | \`${ORG}\` |"
    echo "| **Release type** | \`${RELEASE_TYPE}\` |"
    echo "| **Platform version** | \`${PLATFORM_VERSION}\` |"
    echo "| **Target** | \`${SOURCE_BRANCH}\` → \`${TARGET_BRANCH}\` (via caller PRs) |"
    echo "| **Dry run** | \`${DRY_RUN}\` |"
    echo ""
    echo "Use this list as the **source of truth** for PRs opened by this wave. Open each link, review, and approve/merge."
    echo ""

    if [ "${#CREATED_PRS[@]}" -gt 0 ]; then
      echo "### PRs ready for review (${#CREATED_PRS[@]})"
      echo ""
      local entry pr_url
      for entry in "${CREATED_PRS[@]}"; do
        pr_url="${entry#* }"
        echo "- [$pr_url]($pr_url)"
      done
      echo ""
    fi

    if [ "${#EXISTING_PRS[@]}" -gt 0 ]; then
      echo "### Existing / re-used PRs (${#EXISTING_PRS[@]})"
      echo ""
      local entry pr_url
      for entry in "${EXISTING_PRS[@]}"; do
        pr_url="${entry#* }"
        echo "- [$pr_url]($pr_url)"
      done
      echo ""
    fi

    if [ "${#FAILED_REPOS[@]}" -gt 0 ]; then
      echo "### Failed (${#FAILED_REPOS[@]})"
      echo ""
      local entry
      for entry in "${FAILED_REPOS[@]}"; do
        echo "- $entry"
      done
      echo ""
    fi

    if [ "${#SKIPPED_REPOS[@]}" -gt 0 ]; then
      echo "### Skipped / no PR found (${#SKIPPED_REPOS[@]})"
      echo ""
      local entry
      for entry in "${SKIPPED_REPOS[@]}"; do
        echo "- $entry"
      done
      echo ""
    fi

    if [ "${#DRY_RUN_REPOS[@]}" -gt 0 ]; then
      echo "### Dry-run plan (${#DRY_RUN_REPOS[@]}) - no PRs created"
      echo ""
      local entry
      for entry in "${DRY_RUN_REPOS[@]}"; do
        echo "- $entry"
      done
      echo ""
    fi

    if [ "${#CREATED_PRS[@]}" -eq 0 ] && [ "${#EXISTING_PRS[@]}" -eq 0 ] \
      && [ "${#FAILED_REPOS[@]}" -eq 0 ] && [ "${#SKIPPED_REPOS[@]}" -eq 0 ] \
      && [ "${#DRY_RUN_REPOS[@]}" -eq 0 ]; then
      echo "_No repos were processed._"
      echo ""
    fi

    echo "---"
    echo "_Callers: \`release-train.yml\` (libs/services/rules) opens \`release/v${PLATFORM_VERSION}\` → \`${TARGET_BRANCH}\`; \`dev-to-main-pr.yml\` (non-code) opens \`${SOURCE_BRANCH}\` → \`${TARGET_BRANCH}\`._"
  } >> "$summary_file"
}

log "============================================================"
log "Release orchestrator"
log "  ORG=$ORG"
log "  RELEASE_TYPE=$RELEASE_TYPE"
log "  PLATFORM_VERSION=$PLATFORM_VERSION"
log "  SOURCE_BRANCH=$SOURCE_BRANCH"
log "  TARGET_BRANCH=$TARGET_BRANCH"
log "  PACKAGE_SCOPE=$PACKAGE_SCOPE"
log "  WAIT_PUBLISH=$WAIT_PUBLISH"
log "  WAIT_WORKFLOW=$WAIT_WORKFLOW"
log "  DRY_RUN=$DRY_RUN"
log "  REPO_FILTER=${REPO_FILTER:-<none>}"
log "  List source: org variables REL_LIBS / REL_SERVICES / REL_RULES / REL_NON_CODE"
log "============================================================"

wait_for_latest_run() {
  local full_repo="$1"
  local workflow_file="$2"
  local started_after="$3"

  local run_id=""
  local i=0
  while [ "$i" -lt 30 ]; do
    run_id="$(gh run list -R "$full_repo" --workflow "$workflow_file" --limit 5 \
      --json databaseId,createdAt \
      --jq "[.[] | select(.createdAt >= \"$started_after\")][0].databaseId // empty" 2>/dev/null || true)"
    if [ -n "$run_id" ]; then
      break
    fi
    sleep 2
    i=$((i + 1))
  done

  if [ -z "$run_id" ]; then
    err "Could not find a new run for $workflow_file in $full_repo"
    return 1
  fi

  log "  -> watching run $run_id (timeout ${RUN_TIMEOUT}s)"
  if ! gh run watch "$run_id" -R "$full_repo" --exit-status --interval 10; then
    err "Workflow run $run_id failed for $full_repo"
    gh run view "$run_id" -R "$full_repo" --log-failed 2>/dev/null | tail -n 80 || true
    return 1
  fi
  log "  -> run $run_id succeeded"
}

wait_for_npm_latest() {
  local npm_name="$1"
  if [ -z "$npm_name" ]; then
    log "  -> no npm name; skip publish wait"
    return 0
  fi

  log "  -> waiting for npm $npm_name latest stable (timeout ${PUBLISH_TIMEOUT}s)"
  local elapsed=0
  while [ "$elapsed" -lt "$PUBLISH_TIMEOUT" ]; do
    local ver=""
    ver="$(npm view "$npm_name" dist-tags.latest 2>/dev/null || true)"
    if [ -n "$ver" ] && [[ "$ver" != *-* ]]; then
      log "  -> npm $npm_name@${ver} (latest) visible"
      return 0
    fi
    sleep "$PUBLISH_POLL"
    elapsed=$((elapsed + PUBLISH_POLL))
  done
  err "Timed out waiting for stable latest of $npm_name"
  return 1
}

process_type() {
  local type="$1"
  local raw filtered workflow_file pr_head
  raw="$(list_for_type "$type")"
  filtered="$(filter_list "$raw")"
  workflow_file="$(caller_for_type "$type")"
  pr_head="$(pr_head_for_type "$type")"

  if [ -z "$filtered" ]; then
    log "[$type] no repos (org variable empty or filter matched nothing) - skipping"
    return 0
  fi

  local -a repos=()
  IFS=',' read -r -a repos <<< "$filtered"
  local count="${#repos[@]}"
  log ""
  log "---------- [$type] $count repo(s) - order from REL_$(echo "$type" | tr 'a-z-' 'A-Z_') ----------"
  log "  sequence: $filtered"
  log "  PR head expected: $pr_head → $TARGET_BRANCH"

  local idx=0
  local name full_repo npm_name started_after pr_url pr_before
  for name in "${repos[@]}"; do
    name="$(echo "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$name" ] && continue
    idx=$((idx + 1))
    full_repo="${ORG}/${name}"
    npm_name="${PACKAGE_SCOPE}/${name}"

    log ""
    log "[$type] ($idx/$count) $name"
    log "  -> caller=$workflow_file ref=$SOURCE_BRANCH version=$PLATFORM_VERSION"

    if truthy "$DRY_RUN"; then
      if [ "$workflow_file" = "dev-to-main-pr.yml" ]; then
        log "  DRY_RUN: gh workflow run $workflow_file -R $full_repo --ref $SOURCE_BRANCH -f release_version=$PLATFORM_VERSION"
      else
        log "  DRY_RUN: gh workflow run $workflow_file -R $full_repo --ref $SOURCE_BRANCH -f version=$PLATFORM_VERSION"
      fi
      DRY_RUN_REPOS+=("$full_repo ($type → $workflow_file, head $pr_head)")
      continue
    fi

    pr_before="$(find_release_pr "$full_repo" "$pr_head")"
    started_after="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    if [ "$workflow_file" = "dev-to-main-pr.yml" ]; then
      gh workflow run "$workflow_file" -R "$full_repo" --ref "$SOURCE_BRANCH" \
        -f "release_version=${PLATFORM_VERSION}"
    else
      gh workflow run "$workflow_file" -R "$full_repo" --ref "$SOURCE_BRANCH" \
        -f "version=${PLATFORM_VERSION}"
    fi

    if truthy "$WAIT_WORKFLOW"; then
      sleep 5
      if ! wait_for_latest_run "$full_repo" "$workflow_file" "$started_after"; then
        FAILED_REPOS+=("$full_repo ($type - caller workflow failed)")
        continue
      fi
    fi

    # Collect PR opened/updated by the caller (same pattern as Sync Workflows summary)
    pr_url="$(find_release_pr "$full_repo" "$pr_head")"
    if [ -n "$pr_url" ]; then
      log "  -> PR: $pr_url"
      if [ -n "$pr_before" ] && [ "$pr_before" = "$pr_url" ]; then
        EXISTING_PRS+=("$full_repo $pr_url")
      else
        CREATED_PRS+=("$full_repo $pr_url")
      fi
    else
      log "  -> warning: no open PR found for head=$pr_head base=$TARGET_BRANCH"
      SKIPPED_REPOS+=("$full_repo ($type - caller ran but no PR found for $pr_head → $TARGET_BRANCH)")
    fi

    if truthy "$WAIT_PUBLISH" && [ "${REL_WAIT_MERGE:-false}" = "true" ] && [ "$type" != "non-code" ]; then
      wait_for_npm_latest "$npm_name"
    elif truthy "$WAIT_PUBLISH" && [ "$type" != "non-code" ]; then
      log "  -> note: merge the release PR so publish.yml can publish $npm_name before dependents that need it"
    fi
  done
}

for t in "${types_to_run[@]}"; do
  process_type "$t"
done

write_step_summary

log ""
log "============================================================"
log "Orchestrator finished (type=$RELEASE_TYPE org=$ORG)"
log "PR summary written to job Summary (Actions UI)"
log "To add/reorder repos later: edit org variable REL_LIBS / REL_SERVICES / REL_RULES / REL_NON_CODE"
log "============================================================"

if [ "${#FAILED_REPOS[@]}" -gt 0 ]; then
  exit 1
fi
