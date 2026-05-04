#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_TESTS=1

if [[ "${1:-}" == "--no-test" ]]; then
  RUN_TESTS=0
elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'USAGE'
Usage: scripts/refresh-dependencies.sh [--no-test]

Refresh every Go module below this workspace:
  - normalize GitHub Actions Go setup to use go.mod
  - run go get -u all
  - run go mod tidy
  - run go test ./... unless --no-test is supplied
USAGE
  exit 0
fi

"$ROOT/scripts/normalize-go-workflows.sh"

status=0
while IFS= read -r gomod; do
  module_dir="$(dirname "$gomod")"
  module_name="${module_dir#$ROOT/}"

  echo "==> $module_name"
  if ! (
    cd "$module_dir"
    go get -u all
    go mod tidy
    if [[ "$RUN_TESTS" -eq 1 ]]; then
      go test ./...
    fi
  ); then
    status=1
  fi
done < <(
  find "$ROOT" \
    -path '*/.git' -prune -o \
    -path '*/vendor' -prune -o \
    -path '*/_deps' -prune -o \
    -name go.mod -type f -print | sort
)

exit "$status"
