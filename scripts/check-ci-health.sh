#!/usr/bin/env bash
# check-ci-health.sh — Check GitHub Actions CI status across all remote repos
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OWNER="dl-alexandre"
DAYS=7

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --days|-d) DAYS="$2"; shift 2 ;;
    --failed-only|-f) FAILED_ONLY=1; shift ;;
    --help|-h) cat <<'USAGE'; exit 0 ;;
Usage: scripts/check-ci-health.sh [options]

Check recent GitHub Actions run status across all tool repos.

Options:
  -d, --days N         Look back N days (default: 7)
  -f, --failed-only    Only show repos with failed runs

Reports the most recent run for each workflow, flagging failures.
Requires: gh CLI authenticated.
USAGE
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Collect all repo names from .gitmodules (filtering to actual tool repos)
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

echo "Checking ${#REPOS[@]} repos for runs in the last $DAYS days..."
echo ""

FAILURES=0

for repo in "${REPOS[@]}"; do
  # Get workflows and their latest run
  runs_json="$(gh run list --repo "$OWNER/$repo" --limit 20 --created ">$(date -u -v-${DAYS}d +%Y-%m-%d 2>/dev/null || date -u -d "${DAYS} days ago" +%Y-%m-%d)" --json name,status,conclusion,event,createdAt,headBranch,url 2>/dev/null || true)"

  if [[ -z "$runs_json" || "$runs_json" == "[]" ]]; then
    [[ "${FAILED_ONLY:-}" == "1" ]] || echo "    $repo  — no recent runs"
    continue
  fi

  # Check for any failures
  failed_count="$(echo "$runs_json" | jq '[.[] | select(.conclusion == "failure")] | length')"

  if [[ "$failed_count" -gt 0 ]]; then
    echo "❌ $repo  ($failed_count failed run(s))"
    echo "$runs_json" | jq -r '.[] | select(.conclusion == "failure") | "   \(.createdAt) \(.event) \(.name)"' | head -5
    FAILURES=$((FAILURES + 1))
  else
    [[ "${FAILED_ONLY:-}" == "1" ]] || echo "✅ $repo  — all recent runs passed"
  fi
done

echo ""
if [[ "$FAILURES" -eq 0 ]]; then
  echo "No failures detected across all repos."
else
  echo "$FAILURES repo(s) had failures in the last $DAYS days."
  exit 1
fi
