#!/usr/bin/env bash
# check-template-drift.sh — Flag Tools/* submodules drifting from the cli-template baseline
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISSUES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) cat <<'USAGE'; exit 0 ;;
Usage: scripts/check-template-drift.sh

For each Tools/* submodule (excluding cli-template), verify the fleet baseline:
  - README.md, LICENSE, Makefile present
  - .golangci.yml present and in golangci-lint v2 format (version: "2")
  - .github/workflows/ci.yml and release.yml present
  - a .goreleaser.yml or .goreleaser.yaml present
  - go.mod go directive matches the fleet's most common version (outliers flagged)

Requires submodules to be checked out (git submodule update --init Tools/...).
Exits non-zero if any check fails. Go version outliers are warnings only.
USAGE
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

tools=()
while read -r _ path; do
  [[ "$path" == Tools/* && "$path" != "Tools/cli-template" ]] || continue
  if [[ ! -e "$ROOT/$path/go.mod" ]]; then
    echo "⚠️  $path — not checked out, skipping"
    continue
  fi
  tools+=("$path")
done < <(git -C "$ROOT" config -f .gitmodules --get-regexp '^submodule\..*\.path$')

# Fleet Go version policy: every tool should use the modal go directive.
declare -a go_versions=()
for t in "${tools[@]}"; do
  go_versions+=("$(awk '/^go /{print $2; exit}' "$ROOT/$t/go.mod")")
done
baseline="$(printf '%s\n' "${go_versions[@]}" | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
echo "Fleet Go baseline (modal go directive): $baseline"
echo ""

for i in "${!tools[@]}"; do
  t="${tools[$i]}"
  bad=()

  for f in README.md LICENSE Makefile; do
    [[ -f "$ROOT/$t/$f" ]] || bad+=("missing $f")
  done

  for wf in ci.yml release.yml; do
    [[ -f "$ROOT/$t/.github/workflows/$wf" ]] || bad+=("missing .github/workflows/$wf")
  done

  if [[ ! -f "$ROOT/$t/.goreleaser.yml" && ! -f "$ROOT/$t/.goreleaser.yaml" ]]; then
    bad+=("missing .goreleaser.yml")
  fi

  if [[ ! -f "$ROOT/$t/.golangci.yml" ]]; then
    bad+=("missing .golangci.yml")
  elif ! grep -q '^version: "2"' "$ROOT/$t/.golangci.yml"; then
    bad+=(".golangci.yml is not v2 format (needs 'version: \"2\"')")
  fi

  warn=""
  if [[ "${go_versions[$i]}" != "$baseline" ]]; then
    warn=" (⚠️  go ${go_versions[$i]}, fleet baseline $baseline)"
  fi

  if [[ ${#bad[@]} -eq 0 ]]; then
    echo "✅ $t$warn"
  else
    echo "❌ $t$warn"
    for b in "${bad[@]}"; do echo "     - $b"; done
    ISSUES=$((ISSUES + ${#bad[@]}))
  fi
done

echo ""
if [[ "$ISSUES" -eq 0 ]]; then
  echo "No template drift detected."
else
  echo "$ISSUES drift issue(s) found."
  exit 1
fi
