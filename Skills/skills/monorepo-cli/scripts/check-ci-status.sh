#!/bin/bash
# check-ci-status.sh - Check CI status for all monorepo projects
# Usage: ./check-ci-status.sh [--json]

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
    
    # Get latest CI run
    ci_info=$(gh run list -R "$repo" --limit 1 --json status,conclusion,displayTitle,createdAt,url 2>/dev/null || echo '[]')
    
    if [ "$ci_info" = "[]" ]; then
        status="unknown"
        conclusion="no_runs"
        title="No CI runs found"
    else
        status=$(echo "$ci_info" | jq -r '.[0].status')
        conclusion=$(echo "$ci_info" | jq -r '.[0].conclusion')
        title=$(echo "$ci_info" | jq -r '.[0].displayTitle')
    fi
    
    if $OUTPUT_JSON; then
        results+=$(printf '{"project":"%s","repo":"%s","status":"%s","conclusion":"%s","title":"%s"},' "$project" "$repo" "$status" "$conclusion" "$title")
    else
        emoji="❓"
        [ "$conclusion" = "success" ] && emoji="✅"
        [ "$conclusion" = "failure" ] && emoji="❌"
        [ "$conclusion" = "no_runs" ] && emoji="⚠️"
        printf "%s %-25s [%s] %s\n" "$emoji" "$project" "$conclusion" "$title"
    fi
done

if $OUTPUT_JSON; then
    # Remove trailing comma and wrap in array
    results="[${results%,}]"
    echo "$results" | jq '.'
fi
