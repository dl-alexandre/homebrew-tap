#!/bin/bash
# sync-check.sh - Check submodule synchronization status
# Usage: ./sync-check.sh

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

echo "🔗 Submodule Sync Check"
echo "─────────────────────────────────────────────────────────────────"

# Read .gitmodules to get all submodules
if [ ! -f ".gitmodules" ]; then
    echo "No .gitmodules file found"
    exit 0
fi

# Parse submodules from .gitmodules
git config --file=.gitmodules --get-regexp path | while read -r key path; do
    name=$(echo "$key" | sed 's/^submodule\.//' | sed 's/\.path$//')
    url=$(git config --file=.gitmodules --get "submodule.$name.url" 2>/dev/null || echo "unknown")
    
    if [ -d "$path/.git" ]; then
        cd "$path"
        current_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
        cd "$ROOT_DIR"
        
        # Get expected commit from superrepo
        expected_commit=$(git ls-tree HEAD "$path" 2>/dev/null | awk '{print $3}' | cut -c1-7 || echo "not tracked")
        
        if [ "$current_commit" = "$expected_commit" ]; then
            echo "✅ $path"
            echo "   Current: $current_commit | Expected: $expected_commit | Status: in sync"
        elif [ "$expected_commit" = "not tracked" ]; then
            echo "⚠️  $path"
            echo "   Current: $current_commit | Status: not tracked in superrepo"
        else
            echo "🔄 $path"
            echo "   Current: $current_commit | Expected: $expected_commit | Status: OUT OF SYNC"
            echo "   URL: $url"
            echo "   Branch: $current_branch"
            echo ""
            echo "   To sync: cd $path && git checkout $expected_commit"
            echo "   Or: git submodule update --init $path"
        fi
    else
        echo "❌ $path"
        echo "   Status: not initialized"
        echo "   URL: $url"
        echo ""
        echo "   To initialize: git submodule update --init $path"
    fi
    echo ""
done

echo ""
echo "Quick Commands:"
echo "  git submodule update --init --recursive    # Initialize all"
echo "  git submodule update --remote --merge      # Update to latest remote"
echo "  git submodule foreach 'git status'         # Check all statuses"
