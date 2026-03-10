#!/bin/bash
# check-release-commits.sh - Check for commits beyond the latest release
# Usage: ./check-release-commits.sh [--json]

set -e

PROJECTS=(
    "App-Store-Connect-CLI:rudrankriyam/App-Store-Connect-CLI"
    "Google-Drive-CLI:dl-alexandre/Google-Drive-CLI"
    "Google-Play-Developer-CLI:dl-alexandre/Google-Play-Developer-CLI"
    "grokipedia-cli:dl-alexandre/Grokipedia-CLI"
    "App-StoreKit-CLI:dl-alexandre/App-StoreKit-CLI"
    "App-Store-Server-CLI:dl-alexandre/App-Store-Server-CLI"
    "Apple-Map-Server-CLI:dl-alexandre/Apple-Map-Server-CLI"
    "MyMarketNews-CLI:dl-alexandre/MyMarketNews-CLI"
    "cimis-cli:dl-alexandre/cimis-cli"
)

OUTPUT_JSON=false
if [ "$1" = "--json" ]; then
    OUTPUT_JSON=true
fi

results=()

for entry in "${PROJECTS[@]}"; do
    IFS=':' read -r project repo <<< "$entry"
    
    # Get latest release
    latest_release=$(gh release list -R "$repo" --limit 1 --json tagName,publishedAt 2>/dev/null || echo '[]')
    
    if [ "$latest_release" = "[]" ]; then
        release_tag="none"
        release_date="N/A"
        commits_since=0
    else
        release_tag=$(echo "$latest_release" | jq -r '.[0].tagName')
        release_date=$(echo "$latest_release" | jq -r '.[0].publishedAt')
        
        # Count commits since release
        commits_since=$(gh api "repos/$repo/compare/$release_tag...HEAD" --jq '.ahead_by' 2>/dev/null || echo "0")
    fi
    
    if $OUTPUT_JSON; then
        results+=$(printf '{"project":"%s","repo":"%s","latest_release":"%s","release_date":"%s","commits_since_release":%s},' "$project" "$repo" "$release_tag" "$release_date" "$commits_since")
    else
        emoji="✅"
        [ "$commits_since" -gt 0 ] && emoji="📦"
        [ "$release_tag" = "none" ] && emoji="⚠️"
        printf "%s %-25s %s (%s commits behind)\n" "$emoji" "$project" "$release_tag" "$commits_since"
    fi
done

if $OUTPUT_JSON; then
    results="[${results%,}]"
    echo "$results" | jq '.'
fi
