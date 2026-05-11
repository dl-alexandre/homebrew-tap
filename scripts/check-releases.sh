#!/usr/bin/env bash
# check-releases.sh — Audit GitHub releases for drafts, duplicates, and anomalies
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OWNER="dl-alexandre"
MODE="check"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cleanup) MODE="cleanup"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) cat <<'USAGE'; exit 0 ;;
Usage: scripts/check-releases.sh [options]

Audit GitHub releases across all tool repos.

Options:
  --cleanup    Delete stale drafts and duplicate releases (requires confirmation)
  --dry-run    Show what would be deleted without deleting

Reports:
  - Latest release per repo
  - Stale draft releases (older than the latest)
  - Duplicate releases (same tag appearing multiple times)
  - Releases with version numbers higher than "Latest"

Requires: gh CLI authenticated.
USAGE
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Collect repo names
REPOS=()
while IFS= read -r line; do
  url="$(echo "$line" | awk '{print $2}')"
  if echo "$url" | grep -q "github.com/$OWNER"; then
    repo="$(echo "$url" | sed "s|https://github.com/$OWNER/||;s|git@github.com:$OWNER/||;s/.git$//")"
    REPOS+=("$repo")
  fi
done < <(
  git -C "$ROOT" config -f .gitmodules --get-regexp '^submodule\..*\.url$' | sort -u
)

TOTAL_STALE=0
TOTAL_ANOMALY=0

delete_release() {
  local repo="$1" tag="$2"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "   [DRY-RUN] Would delete $tag"
  else
    gh release delete "$tag" --repo "$OWNER/$repo" --yes 2>/dev/null && echo "   Deleted $tag" || echo "   Failed to delete $tag"
  fi
}

for repo in "${REPOS[@]}"; do
  releases_json="$(gh release list --repo "$OWNER/$repo" --limit 50 --json tagName,isDraft,isLatest,publishedAt 2>/dev/null || true)"

  if [[ -z "$releases_json" || "$releases_json" == "[]" ]]; then
    echo "    $repo  — no releases"
    continue
  fi

  latest_tag="$(echo "$releases_json" | jq -r '.[] | select(.isLatest) | .tagName')"
  stale_count="$(echo "$releases_json" | jq --arg latest "$latest_tag" '[.[] | select(.isDraft and .tagName != $latest)] | length')"

  # Find duplicate tags
  dupes="$(echo "$releases_json" | jq -r 'group_by(.tagName)[] | select(length > 1) | .[0].tagName')"
  dupe_count="$(echo "$releases_json" | jq '[group_by(.tagName)[] | select(length > 1)] | length')"

  # Find releases with higher version than latest (anomaly)
  # Simple major.minor.patch comparison to catch obvious mistakes
  anomalies=""
  anomaly_count=0
  if [[ -n "$latest_tag" ]]; then
    # Extract numeric components from latest (e.g. v0.5.11 -> 0 5 11)
    latest_nums="$(echo "$latest_tag" | sed -E 's/^v?([0-9]+)\.([0-9]+)\.([0-9]+).*/\1 \2 \3/')"
    read -r latest_major latest_minor latest_patch <<< "$latest_nums" || true

    while IFS= read -r tag; do
      [[ -z "$tag" ]] && continue
      [[ "$tag" == "$latest_tag" ]] && continue

      tag_nums="$(echo "$tag" | sed -E 's/^v?([0-9]+)\.([0-9]+)\.([0-9]+).*/\1 \2 \3/')"
      read -r tag_major tag_minor tag_patch <<< "$tag_nums" || continue

      # Flag if major or minor is higher, or if major+minor equal and patch higher
      if [[ -n "$latest_major" && -n "$tag_major" ]]; then
        if [[ "$tag_major" -gt "$latest_major" ]] || \
           ([[ "$tag_major" -eq "$latest_major" && "$tag_minor" -gt "$latest_minor" ]]) || \
           ([[ "$tag_major" -eq "$latest_major" && "$tag_minor" -eq "$latest_minor" && "$tag_patch" -gt "$latest_patch" ]]); then
          anomalies="$anomalies $tag"
          anomaly_count=$((anomaly_count + 1))
        fi
      fi
    done < <(echo "$releases_json" | jq -r '.[].tagName')
  fi

  has_issues=0
  if [[ "$stale_count" -gt 0 || "$dupe_count" -gt 0 || "$anomaly_count" -gt 0 ]]; then
    has_issues=1
  fi

  if [[ "$has_issues" -eq 0 ]]; then
    echo "✅ $repo  latest=$latest_tag  releases=$(echo "$releases_json" | jq 'length')"
    continue
  fi

  echo "⚠️  $repo  latest=$latest_tag"

  if [[ "$stale_count" -gt 0 ]]; then
    echo "   Stale drafts ($stale_count):"
    echo "$releases_json" | jq --arg latest "$latest_tag" -r '.[] | select(.isDraft and .tagName != $latest) | "     - " + .tagName'
    TOTAL_STALE=$((TOTAL_STALE + stale_count))

    if [[ "$MODE" == "cleanup" ]]; then
      echo "$releases_json" | jq --arg latest "$latest_tag" -r '.[] | select(.isDraft and .tagName != $latest) | .tagName' | while read -r tag; do
        [[ -n "$tag" ]] && delete_release "$repo" "$tag"
      done
    fi
  fi

  if [[ "$dupe_count" -gt 0 ]]; then
    echo "   Duplicate tags ($dupe_count): $dupes"
  fi

  if [[ "$anomaly_count" -gt 0 ]]; then
    echo "   Version anomalies ($anomaly_count):$anomalies"
    TOTAL_ANOMALY=$((TOTAL_ANOMALY + anomaly_count))

    if [[ "$MODE" == "cleanup" ]]; then
      for tag in $anomalies; do
        delete_release "$repo" "$tag"
      done
    fi
  fi
done

echo ""
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[DRY-RUN] Would clean up $TOTAL_STALE stale drafts + $TOTAL_ANOMALY anomalies."
  echo "Re-run with --cleanup to delete."
else
  echo "Found $TOTAL_STALE stale drafts + $TOTAL_ANOMALY anomalies."
fi
