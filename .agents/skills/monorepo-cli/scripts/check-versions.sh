#!/bin/bash
# check-versions.sh - Check current version of each CLI project
# Usage: ./check-versions.sh [--json]

set -e

PROJECTS=(
    "App-Store-Connect-CLI:rudrankriyam/App-Store-Connect-CLI:./cmd/asc"
    "Google-Drive-CLI:dl-alexandre/Google-Drive-CLI:./cmd/gdrv"
    "Google-Play-Developer-CLI:dl-alexandre/Google-Play-Developer-CLI:./cmd/gpd"
    "grokipedia-cli:dl-alexandre/Grokipedia-CLI:."
    "App-StoreKit-CLI:dl-alexandre/App-StoreKit-CLI:./cmd/ask"
    "App-Store-Server-CLI:dl-alexandre/App-Store-Server-CLI:./cmd/ass"
    "Apple-Map-Server-CLI:dl-alexandre/Apple-Map-Server-CLI:./cmd/ams"
    "MyMarketNews-CLI:dl-alexandre/MyMarketNews-CLI:."
    "cimis-cli:dl-alexandre/cimis-cli:."
)

OUTPUT_JSON=false
if [ "$1" = "--json" ]; then
    OUTPUT_JSON=true
fi

results=()

for entry in "${PROJECTS[@]}"; do
    IFS=':' read -r project repo entry_path <<< "$entry"
    local_path="$project"
    
    version="unknown"
    
    # Try to get version from git tag
    if [ -d "$local_path/.git" ]; then
        cd "$local_path"
        version=$(git describe --tags --always 2>/dev/null || echo "unknown")
        cd - > /dev/null
    fi
    
    # Try to get version from main.go or version file
    if [ "$version" = "unknown" ] && [ -d "$local_path" ]; then
        if [ -f "$local_path/main.go" ]; then
            version=$(grep -o 'version.*=.*"[^"]*"' "$local_path/main.go" 2>/dev/null | head -1 | grep -o '"[^"]*"' | tr -d '"' || echo "unknown")
        fi
    fi
    
    # Try to get latest release version from GitHub
    if command -v gh >/dev/null 2>&1; then
        gh_version=$(gh release list -R "$repo" --limit 1 --json tagName 2>/dev/null | jq -r '.[0].tagName' || echo "")
        if [ -n "$gh_version" ] && [ "$gh_version" != "null" ]; then
            version="$gh_version"
        fi
    fi
    
    if $OUTPUT_JSON; then
        results+=$(printf '{"project":"%s","repo":"%s","version":"%s"},' "$project" "$repo" "$version")
    else
        printf "%-25s %s\n" "$project" "$version"
    fi
done

if $OUTPUT_JSON; then
    results="[${results%,}]"
    echo "$results" | jq '.'
fi
