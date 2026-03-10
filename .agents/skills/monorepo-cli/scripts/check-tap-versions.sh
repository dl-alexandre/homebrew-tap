#!/bin/bash
# check-tap-versions.sh - Check if homebrew formulas match latest releases
# Usage: ./check-tap-versions.sh [--update]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]})")" && pwd)"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TAP_DIR="${ROOT_DIR}/homebrew-tap"
FORMULA_DIR="${TAP_DIR}/Formula"

UPDATE_MODE=false
if [ "${1:-}" = "--update" ]; then
    UPDATE_MODE=true
fi

echo "🔍 Checking Homebrew Tap Versions"
echo "===================================="
echo ""

# Map formula names to GitHub repos
# Format: "formula_name:github_repo:binary_name"
FORMULAS=(
    "abc:dl-alexandre/Apple-Business-Connect-CLI:abc"
    "ams:dl-alexandre/Apple-Map-Server-CLI:ams"
    "ask:dl-alexandre/App-StoreKit-CLI:ask"
    "cimis:dl-alexandre/cimis-cli:cimis"
    "cli-template:dl-alexandre/cli-template:cli-template"
    "gdrv:dl-alexandre/Google-Drive-CLI:gdrv"
    "gpd:dl-alexandre/Google-Play-Developer-CLI:gpd"
    "mpr:dl-alexandre/MyMarketNews-CLI:mpr"
    "unifi:dl-alexandre/Local-UniFi-CLI:unifi"
    "usm:dl-alexandre/UniFi-Site-Manager-CLI:usm"
    "x:dl-alexandre/X-CLI:x"
)

needs_update=0

for entry in "${FORMULAS[@]}"; do
    IFS=':' read -r formula repo binary <<< "$entry"
    formula_file="${FORMULA_DIR}/${formula}.rb"
    
    if [ ! -f "$formula_file" ]; then
        echo "⚠️  $formula: Formula file not found"
        continue
    fi
    
    # Get latest release from GitHub
    latest_release=$(gh release list -R "$repo" --limit 1 --json tagName 2>/dev/null || echo '[]')
    latest_version=$(echo "$latest_release" | jq -r '.[0].tagName // "none"')
    
    if [ "$latest_version" = "none" ]; then
        echo "⚠️  $formula: No releases found for $repo"
        continue
    fi
    
    # Get current version from formula
    current_version=$(grep -E '^\s+version\s+' "$formula_file" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    
    # Check if SHA256 needs updating
    has_placeholder=false
    if grep -q "TO_BE_UPDATED" "$formula_file"; then
        has_placeholder=true
    fi
    
    # Compare versions
    if [ "$current_version" != "$latest_version" ] || [ "$has_placeholder" = true ]; then
        needs_update=$((needs_update + 1))
        echo "🔄 $formula: OUTDATED"
        echo "   Current: $current_version"
        echo "   Latest:  $latest_version"
        if [ "$has_placeholder" = true ]; then
            echo "   Status:  SHA256 placeholders need updating"
        fi
        echo "   Repo:    https://github.com/$repo/releases"
        echo ""
    else
        echo "✅ $formula: $current_version (up to date)"
    fi
done

echo ""
echo "===================================="
if [ $needs_update -gt 0 ]; then
    echo "⚠️  Found $needs_update formula(s) needing updates"
    echo ""
    echo "To update a formula:"
    echo "  1. Download the latest release binaries"
    echo "  2. Calculate SHA256: shasum -a 256 <file>"
    echo "  3. Update version and SHA in Formula/<name>.rb"
    echo ""
    echo "Or run with --update flag to auto-update (requires gh CLI):"
    echo "  ./check-tap-versions.sh --update"
    exit 1
else
    echo "✅ All formulas are up to date!"
    exit 0
fi
