#!/bin/bash
# check-status.sh - Check status of all CLI projects
# Usage: ./check-status.sh [--json] [--embedded|--submodules|--github]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

# Configuration
EMBEDDED_REPOS=(
    "Advance-Commerce-CLI"
    "App-StoreKit-CLI"
    "Apple-Business-Connect-CLI"
    "Apple-Map-Server-CLI"
    "cimis-cli"
    "cli-template"
    "Google-Drive-CLI"
    "Google-Play-Developer-CLI"
    "Grokipedia-CLI"
    "Local-UniFi-CLI"
    "MyMarketNews-CLI"
    "UniFi-Site-Manager-CLI"
    "UPS-CLI"
)

SUBMODULES=(
    "Skills"
    "X-CLI"
    "homebrew-tap"
)

GITHUB_REPOS=(
    "App-StoreKit-CLI:dl-alexandre/App-StoreKit-CLI"
)

# Parse arguments
OUTPUT_JSON=false
FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            OUTPUT_JSON=true
            shift
            ;;
        --embedded)
            FILTER="embedded"
            shift
            ;;
        --submodules)
            FILTER="submodules"
            shift
            ;;
        --github)
            FILTER="github"
            shift
            ;;
        *)
            echo "Usage: $0 [--json] [--embedded|--submodules|--github]"
            exit 1
            ;;
    esac
done

# Function to check embedded repo status
check_embedded() {
    local dir=$1
    local results=""
    
    if [ -d "$dir/.git" ]; then
        cd "$dir"
        
        # Get git status
        local dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        local branch=$(git branch --show-current 2>/dev/null || echo "detached")
        local last_commit=$(git log -1 --format=%cd --date=short 2>/dev/null || echo "N/A")
        local ahead_behind=$(git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null || echo "0 0")
        local ahead=$(echo "$ahead_behind" | awk '{print $1}')
        local behind=$(echo "$ahead_behind" | awk '{print $2}')
        
        cd "$ROOT_DIR"
        
        if $OUTPUT_JSON; then
            results=$(printf '{"type":"embedded","name":"%s","dirty":%s,"branch":"%s","last_commit":"%s","ahead":%s,"behind":%s}' \
                "$dir" "$dirty" "$branch" "$last_commit" "$ahead" "$behind")
        else
            local status_emoji="✅"
            [ "$dirty" -gt 0 ] && status_emoji="⚠️"
            [ "$ahead" -gt 0 ] && status_emoji="⬆️"
            [ "$behind" -gt 0 ] && status_emoji="⬇️"
            [ "$dirty" -gt 0 ] && [ "$ahead" -gt 0 ] && status_emoji="⚠️⬆️"
            
            local sync_status=""
            [ "$ahead" -gt 0 ] && sync_status=" (+$ahead)"
            [ "$behind" -gt 0 ] && sync_status=" (-$behind)"
            
            printf "%s %-25s [%s] %s uncommitted%s\n" "$status_emoji" "$dir" "$branch" "$dirty" "$sync_status"
        fi
    else
        if $OUTPUT_JSON; then
            results=$(printf '{"type":"embedded","name":"%s","status":"not_git_repo"}' "$dir")
        else
            printf "❌ %-25s (not a git repository)\n" "$dir"
        fi
    fi
    
    echo "$results"
}

# Function to check submodule status
check_submodule() {
    local name=$1
    local results=""
    
    if [ -d "$name/.git" ]; then
        cd "$name"
        
        # Get current commit
        local current_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        local expected_commit=$(git ls-tree HEAD "$name" 2>/dev/null | awk '{print $3}' || echo "unknown")
        local in_sync="true"
        [ "$current_commit" != "$expected_commit" ] && [ "$expected_commit" != "unknown" ] && in_sync="false"
        
        local dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        local branch=$(git branch --show-current 2>/dev/null || echo "detached")
        
        cd "$ROOT_DIR"
        
        if $OUTPUT_JSON; then
            results=$(printf '{"type":"submodule","name":"%s","current":"%s","expected":"%s","in_sync":%s,"dirty":%s,"branch":"%s"}' \
                "$name" "$current_commit" "$expected_commit" "$in_sync" "$dirty" "$branch")
        else
            local status_emoji="✅"
            [ "$in_sync" = "false" ] && status_emoji="🔄"
            [ "$dirty" -gt 0 ] && status_emoji="⚠️"
            
            local sync_text="in sync"
            [ "$in_sync" = "false" ] && sync_text="out of sync"
            
            printf "%s %-25s [%s] %s (%s)\n" "$status_emoji" "$name" "$branch" "$current_commit" "$sync_text"
        fi
    else
        if $OUTPUT_JSON; then
            results=$(printf '{"type":"submodule","name":"%s","status":"not_initialized"}' "$name")
        else
            printf "⚠️  %-25s (submodule not initialized)\n" "$name"
        fi
    fi
    
    echo "$results"
}

# Function to check GitHub repo status
check_github() {
    local project=$1
    local repo=$2
    local results=""
    
    if command -v gh >/dev/null 2>&1; then
        local ci_info=$(gh run list -R "$repo" --limit 1 --json status,conclusion,displayTitle 2>/dev/null || echo '[]')
        local latest_release=$(gh release list -R "$repo" --limit 1 --json tagName 2>/dev/null || echo '[]')
        
        local status="unknown"
        local conclusion="no_runs"
        if [ "$ci_info" != "[]" ]; then
            status=$(echo "$ci_info" | jq -r '.[0].status')
            conclusion=$(echo "$ci_info" | jq -r '.[0].conclusion')
        fi
        
        local release=$(echo "$latest_release" | jq -r '.[0].tagName // "none"')
        
        if $OUTPUT_JSON; then
            results=$(printf '{"type":"github","name":"%s","repo":"%s","ci_status":"%s","ci_conclusion":"%s","latest_release":"%s"}' \
                "$project" "$repo" "$status" "$conclusion" "$release")
        else
            local emoji="❓"
            [ "$conclusion" = "success" ] && emoji="✅"
            [ "$conclusion" = "failure" ] && emoji="❌"
            [ "$conclusion" = "no_runs" ] && emoji="⚠️"
            
            printf "%s %-25s CI:%s Release:%s\n" "$emoji" "$project" "$conclusion" "$release"
        fi
    else
        if $OUTPUT_JSON; then
            results=$(printf '{"type":"github","name":"%s","repo":"%s","status":"gh_not_installed"}' "$project" "$repo")
        else
            printf "⚠️  %-25s (gh CLI not installed)\n" "$project"
        fi
    fi
    
    echo "$results"
}

# Main execution
json_results=()

# Check embedded repos
if [ -z "$FILTER" ] || [ "$FILTER" = "embedded" ]; then
    [ -z "$FILTER" ] && ! $OUTPUT_JSON && echo "📁 Embedded Repositories:"
    [ -z "$FILTER" ] && ! $OUTPUT_JSON && echo "─────────────────────────────────────────────────────────────────"
    
    for dir in "${EMBEDDED_REPOS[@]}"; do
        if [ -d "$dir" ]; then
            result=$(check_embedded "$dir")
            $OUTPUT_JSON && json_results+=("$result")
        fi
    done
fi

# Check submodules
if [ -z "$FILTER" ] || [ "$FILTER" = "submodules" ]; then
    [ -z "$FILTER" ] && ! $OUTPUT_JSON && echo ""
    [ -z "$FILTER" ] && ! $OUTPUT_JSON && echo "🔗 Submodules:"
    [ -z "$FILTER" ] && ! $OUTPUT_JSON && echo "─────────────────────────────────────────────────────────────────"
    
    for name in "${SUBMODULES[@]}"; do
        result=$(check_submodule "$name")
        $OUTPUT_JSON && json_results+=("$result")
    done
fi

# Check GitHub repos
if [ -z "$FILTER" ] || [ "$FILTER" = "github" ]; then
    [ -z "$FILTER" ] && ! $OUTPUT_JSON && echo ""
    [ -z "$FILTER" ] && ! $OUTPUT_JSON && echo "🌐 GitHub Repositories:"
    [ -z "$FILTER" ] && ! $OUTPUT_JSON && echo "─────────────────────────────────────────────────────────────────"
    
    for entry in "${GITHUB_REPOS[@]}"; do
        IFS=':' read -r project repo <<< "$entry"
        result=$(check_github "$project" "$repo")
        $OUTPUT_JSON && json_results+=("$result")
    done
fi

# Output JSON if requested
if $OUTPUT_JSON; then
    # Convert array to JSON
    printf '[%s]' "$(IFS=,; echo "${json_results[*]}")" | jq '.'
fi
