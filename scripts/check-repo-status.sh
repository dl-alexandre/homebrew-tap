#!/usr/bin/env bash
# check-repo-status.sh — Check git status across the parent repo and all submodules
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NO_CHANGES=1

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'USAGE'
Usage: scripts/check-repo-status.sh

Check git status across the parent repository and all initialized submodules.
Reports:
  - clean repos
  - repos with uncommitted changes (working tree dirty)
  - repos ahead of remote
  - repos behind remote
  - uninitialized submodules
USAGE
  exit 0
fi

echo "==> Parent repo"
cd "$ROOT"
PARENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'HEAD')"
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  PARENT_CHANGES=""
else
  PARENT_CHANGES=" (uncommitted changes)"
  NO_CHANGES=0
fi
PARENT_AHEAD="$(git rev-list --count HEAD..@{u} 2>/dev/null || echo '?')"
PARENT_BEHIND="$(git rev-list --count @{u}..HEAD 2>/dev/null || echo '?')"
echo "    $PARENT_BRANCH  ahead:$PARENT_AHEAD behind:$PARENT_BEHIND$PARENT_CHANGES"

echo ""
echo "==> Submodules"
while IFS= read -r line; do
  # Parse: [ -]<sha> <path> [optional extra]
  prefix="${line:0:1}"
  rest="${line:1}"
  sha="$(echo "$rest" | awk '{print $1}')"
  path="$(echo "$rest" | awk '{print $2}')"

  if [[ "$prefix" == "-" ]]; then
    echo "    $path  (not initialized)"
    NO_CHANGES=0
    continue
  fi

  cd "$ROOT/$path"
  BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'HEAD')"
  CHANGES=""
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
    CHANGES=" (uncommitted changes)"
    NO_CHANGES=0
  fi

  UPSTREAM="$(git rev-parse --abbrev-ref HEAD@{u} 2>/dev/null || true)"
  if [[ -n "$UPSTREAM" ]]; then
    AHEAD="$(git rev-list --count HEAD..@{u} 2>/dev/null || echo '0')"
    BEHIND="$(git rev-list --count @{u}..HEAD 2>/dev/null || echo '0')"
    echo "    $path  $BRANCH  ahead:$AHEAD behind:$BEHIND$CHANGES"
  else
    echo "    $path  $BRANCH  (no upstream)$CHANGES"
  fi
done < <(git -C "$ROOT" submodule status)

if [[ "$NO_CHANGES" -eq 1 ]]; then
  echo ""
  echo "All repos clean."
  exit 0
else
  exit 1
fi
