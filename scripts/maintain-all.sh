#!/usr/bin/env bash
# maintain-all.sh — Master maintenance script orchestrating all checks
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKIP_TESTS=0
SKIP_CI=0
SKIP_RELEASES=0
SKIP_SUBMODULES=0
SKIP_REFRESH=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-test) SKIP_TESTS=1; shift ;;
    --skip-ci) SKIP_CI=1; shift ;;
    --skip-releases) SKIP_RELEASES=1; shift ;;
    --skip-submodules) SKIP_SUBMODULES=1; shift ;;
    --skip-refresh|--check-only) SKIP_REFRESH=1; shift ;;
    --help|-h) cat <<'USAGE'; exit 0 ;;
Usage: scripts/maintain-all.sh [options]

Run the full maintenance suite across the workspace:
  1. Check local repo + submodule status
  2. Check submodule pointers against remotes
  3. Refresh Go dependencies (unless --skip-refresh)
  4. Check CI health across all remotes (unless --skip-ci)
  5. Audit releases for stale drafts (unless --skip-releases)

Options:
  --no-test           Skip Go test suite during dependency refresh
  --skip-refresh      Skip Go dependency refresh entirely
  --check-only        Alias for --skip-refresh
  --skip-ci           Skip remote CI health check
  --skip-releases     Skip release audit
  --skip-submodules   Skip submodule pointer check
  --help, -h          Show this help

Requires: git, go, gh CLI authenticated.
USAGE
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

FAILED=0

echo "══════════════════════════════════════════════════════════════"
echo "  CLI-Tools Maintenance Run"
echo "  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "══════════════════════════════════════════════════════════════"
echo ""

# 1. Local repo status
echo "──────────────────────────────────────────────────────────────"
echo "1. Local repository status"
echo "──────────────────────────────────────────────────────────────"
if "$ROOT/scripts/check-repo-status.sh"; then
  echo "   ✅ All clean"
else
  echo "   ⚠️  Some repos have changes — review above"
  FAILED=1
fi
echo ""

# 2. Submodule pointers
if [[ "$SKIP_SUBMODULES" -eq 0 ]]; then
  echo "──────────────────────────────────────────────────────────────"
  echo "2. Submodule pointer check"
  echo "──────────────────────────────────────────────────────────────"
  if "$ROOT/scripts/check-submodule-pointers.sh"; then
    echo "   ✅ All pointers up to date"
  else
    echo "   ⚠️  Some submodules are behind — run with --update to fast-forward"
    FAILED=1
  fi
  echo ""
fi

# 3. Refresh dependencies
if [[ "$SKIP_REFRESH" -eq 1 ]]; then
  echo "──────────────────────────────────────────────────────────────"
  echo "3. Dependency refresh (skipped)"
  echo "──────────────────────────────────────────────────────────────"
  echo "   Skipped by --skip-refresh"
elif [[ "$SKIP_TESTS" -eq 1 ]]; then
  echo "──────────────────────────────────────────────────────────────"
  echo "3. Dependency refresh (tests skipped)"
  echo "──────────────────────────────────────────────────────────────"
  "$ROOT/scripts/refresh-dependencies.sh" --no-test || FAILED=1
else
  echo "──────────────────────────────────────────────────────────────"
  echo "3. Dependency refresh + tests"
  echo "──────────────────────────────────────────────────────────────"
  "$ROOT/scripts/refresh-dependencies.sh" || FAILED=1
fi
echo ""

# 4. CI health
if [[ "$SKIP_CI" -eq 0 ]]; then
  echo "──────────────────────────────────────────────────────────────"
  echo "4. CI health check (last 7 days)"
  echo "──────────────────────────────────────────────────────────────"
  if "$ROOT/scripts/check-ci-health.sh" --days 7; then
    echo "   ✅ No failures detected"
  else
    echo "   ⚠️  Some repos have failed runs — review above"
    FAILED=1
  fi
  echo ""
fi

# 5. Release audit
if [[ "$SKIP_RELEASES" -eq 0 ]]; then
  echo "──────────────────────────────────────────────────────────────"
  echo "5. Release audit"
  echo "──────────────────────────────────────────────────────────────"
  if "$ROOT/scripts/check-releases.sh"; then
    echo "   ✅ No stale drafts or anomalies"
  else
    echo "   ⚠️  Issues found — run with --cleanup to delete drafts"
    FAILED=1
  fi
  echo ""
fi

echo "══════════════════════════════════════════════════════════════"
if [[ "$FAILED" -eq 0 ]]; then
  echo "  ✅ Maintenance complete — all checks passed"
else
  echo "  ⚠️  Maintenance complete — some issues need attention"
fi
echo "══════════════════════════════════════════════════════════════"

exit "$FAILED"
