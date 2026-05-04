#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

find "$ROOT" \
  -path '*/.git' -prune -o \
  -path '*/vendor' -prune -o \
  -path '*/_deps' -prune -o \
  -path '*/.github/workflows/*' \
  -type f \( -name '*.yml' -o -name '*.yaml' \) \
  -print0 |
while IFS= read -r -d '' workflow; do
  perl -0pi -e '
    s/^\s+go-version:\s+\['\''1\.25(?:\.0|\.x)?'\''\]\n//mg;
    s/^\s+go-version:\s+\['\''1\.23'\'', '\''1\.24'\'', '\''1\.25'\''\]\n//mg;
    s/^(\s*)go-version:\s*(?:\$\{\{\s*matrix\.go-version\s*\}\}|'\''1\.25(?:\.0|\.x)?'\''|"1\.25(?:\.0|\.x)?"|'\''1\.25'\''|"1\.25")\s*$/\1go-version-file: go.mod/mg;
    s/\n    strategy:\n      matrix:\n\n/\n/g;
  ' "$workflow"
done
