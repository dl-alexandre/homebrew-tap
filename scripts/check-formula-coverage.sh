#!/usr/bin/env bash
# check-formula-coverage.sh — Ensure every Tools/* submodule has a Homebrew formula
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MISSING=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) cat <<'USAGE'; exit 0 ;;
Usage: scripts/check-formula-coverage.sh

Verify that each Tools/* submodule has a Formula/*.rb with a matching homepage.
Also flags a stale homebrew-tap/ submodule directory if it reappears.
USAGE
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -d "$ROOT/homebrew-tap/Formula" ]]; then
  echo "❌ homebrew-tap/ submodule directory exists — root Formula/ is the single source of truth"
  MISSING=$((MISSING + 1))
fi

formula_count="$(find "$ROOT/Formula" -maxdepth 1 -name '*.rb' 2>/dev/null | wc -l | tr -d ' ')"
echo "Found $formula_count formula(s) in Formula/"
echo ""

while read -r key path; do
  [[ "$path" == Tools/* ]] || continue

  name="${key#submodule.}"
  name="${name%.path}"
  url="$(git -C "$ROOT" config -f .gitmodules --get "submodule.$name.url")"
  repo_url="https://github.com/${url#*github.com/}"
  repo_url="${repo_url%.git}"

  if grep -rq "homepage \"${repo_url}\"" "$ROOT/Formula/" 2>/dev/null; then
    echo "✅ $path"
  else
    echo "❌ $path — no formula with homepage $repo_url"
    MISSING=$((MISSING + 1))
  fi
done < <(git -C "$ROOT" config -f .gitmodules --get-regexp '^submodule\..*\.path$')

echo ""
if [[ "$MISSING" -eq 0 ]]; then
  echo "All tool submodules have matching formulas."
else
  echo "$MISSING issue(s) found."
  exit 1
fi