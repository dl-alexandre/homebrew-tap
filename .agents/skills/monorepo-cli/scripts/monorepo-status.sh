#!/bin/bash
# monorepo-status.sh - Full status dashboard for all CLI projects
# Usage: ./monorepo-status.sh [--json] [--issues]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

OUTPUT_JSON=false
ISSUES_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            OUTPUT_JSON=true
            shift
            ;;
        --issues)
            ISSUES_ONLY=true
            shift
            ;;
        *)
            echo "Usage: $0 [--json] [--issues]"
            exit 1
            ;;
    esac
done

if $OUTPUT_JSON; then
    # Combined JSON output
    echo "{"
    echo '  "timestamp": "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'",'
    echo '  "status":'
    "$SCRIPT_DIR/check-status.sh" --json | sed 's/^/    /'
    echo ","
    echo '  "versions":'
    "$SCRIPT_DIR/check-versions.sh" --json | sed 's/^/    /'
    echo "}"
else
    # Human-readable dashboard
    if ! $ISSUES_ONLY; then
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║           CLI-Tools Monorepo Status Dashboard                    ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Generated: $(date)"
        echo ""
    fi
    
    # Capture status output
    status_output=$("$SCRIPT_DIR/check-status.sh" 2>&1 || true)
    
    # Check for issues in status output
    has_issues=false
    if echo "$status_output" | grep -qE "(⚠️|❌|🔄|out of sync)"; then
        has_issues=true
    fi
    
    if $ISSUES_ONLY; then
        if $has_issues; then
            echo "⚠️  Issues Detected:"
            echo "─────────────────────────────────────────────────────────────────"
            echo "$status_output" | grep -E "(⚠️|❌|🔄|out of sync)" | head -20
            echo ""
            echo "Run without --issues flag to see full status."
        else
            echo "✅ No issues detected! All projects look good."
        fi
    else
        echo "📊 Repository Status:"
        echo "─────────────────────────────────────────────────────────────────"
        echo "$status_output"
        echo ""
        echo "🏷️  Current Versions:"
        echo "─────────────────────────────────────────────────────────────────"
        "$SCRIPT_DIR/check-versions.sh"
        
        if $has_issues; then
            echo ""
            echo "⚠️  Note: Some projects have issues detected."
            echo "   Run with --issues flag to see only problems."
        fi
        
        echo ""
        echo "─────────────────────────────────────────────────────────────────"
        echo "[S] = Submodule | Run with --json for machine-readable output"
    fi
fi
