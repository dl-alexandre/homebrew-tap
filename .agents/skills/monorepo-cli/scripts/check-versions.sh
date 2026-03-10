#!/bin/bash
# check-versions.sh - Check current version of each CLI project
# Usage: ./check-versions.sh [--json]

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

OUTPUT_JSON=false
if [ "${1:-}" = "--json" ]; then
    OUTPUT_JSON=true
fi

# All projects to check (both embedded and submodules)
TOOLS_DIR="${ROOT_DIR}/Tools"
PROJECTS=(
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
    "Skills"
    "X-CLI"
    "homebrew-tap"
)

json_results=()

for project in "${PROJECTS[@]}"; do
    # Determine full path
    if [ "$project" = "Skills" ] || [ "$project" = "homebrew-tap" ]; then
        full_path="${ROOT_DIR}/${project}"
    else
        full_path="${TOOLS_DIR}/${project}"
    fi
    
    if [ ! -d "$full_path" ]; then
        continue
    fi
    
    version="unknown"
    source="none"
    
    if [ -d "$full_path/.git" ]; then
        cd "$full_path"
        
        # Try git describe for version
        version=$(git describe --tags --always 2>/dev/null || echo "unknown")
        if [ "$version" != "unknown" ]; then
            source="git-tag"
        fi
        
        # If no tags, try to get from go.mod or package.json
        if [ "$version" = "unknown" ] || [[ "$version" == *"g"* ]]; then
            if [ -f "go.mod" ]; then
                # Try to extract module path which might contain version
                module_path=$(head -1 go.mod 2>/dev/null | awk '{print $2}' || echo "")
                if [[ "$module_path" == *"/v"[0-9]* ]]; then
                    version=$(echo "$module_path" | grep -o 'v[0-9]\+' | head -1)
                    source="go.mod"
                fi
            fi
        fi
        
        # Check for version file
        if [ "$version" = "unknown" ] && [ -f "VERSION" ]; then
            version=$(cat VERSION 2>/dev/null | tr -d '[:space:]' || echo "unknown")
            [ "$version" != "unknown" ] && source="VERSION file"
        fi
        
        cd "$ROOT_DIR"
    fi
    
    # Check if it's a submodule and get info from superrepo
    is_submodule=false
    if [ -f ".gitmodules" ] && grep -q "path = .*${project}" .gitmodules 2>/dev/null; then
        is_submodule=true
        if [ "$version" = "unknown" ] || [[ "$version" == *"g"* ]]; then
            # Try to get the commit from superrepo tracking
            super_commit=$(git ls-tree HEAD "$full_path" 2>/dev/null | awk '{print $3}' | cut -c1-7 || echo "")
            if [ -n "$super_commit" ]; then
                version="$super_commit"
                source="superrepo"
            fi
        fi
    fi
    
    if $OUTPUT_JSON; then
        json_results+=("{\"project\":\"$project\",\"version\":\"$version\",\"source\":\"$source\",\"is_submodule\":$is_submodule}")
    else
        submod_marker=""
        $is_submodule && submod_marker=" [S]"
        
        if [ "$version" != "unknown" ]; then
            printf "%-25s %s (%s)%s\n" "$project" "$version" "$source" "$submod_marker"
        else
            printf "%-25s %s%s\n" "$project" "$version" "$submod_marker"
        fi
    fi
done

if $OUTPUT_JSON; then
    printf '[%s]' "$(IFS=,; echo "${json_results[*]}")" | jq '.'
fi
