#!/bin/bash
# monorepo-status.sh - Full status dashboard for all CLI projects
# Usage: ./monorepo-status.sh [--json]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$1" = "--json" ]; then
    echo "{"
    echo '  "ci_status":'
    "$SCRIPT_DIR/check-ci-status.sh" --json | sed 's/^/    /'
    echo ','
    echo '  "release_commits":'
    "$SCRIPT_DIR/check-release-commits.sh" --json | sed 's/^/    /'
    echo ','
    echo '  "versions":'
    "$SCRIPT_DIR/check-versions.sh" --json | sed 's/^/    /'
    echo "}"
else
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           CLI-Tools Monorepo Status Dashboard                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📊 CI Status:"
    echo "─────────────────────────────────────────────────────────────────"
    "$SCRIPT_DIR/check-ci-status.sh"
    echo ""
    echo "📦 Release Status (commits since last release):"
    echo "─────────────────────────────────────────────────────────────────"
    "$SCRIPT_DIR/check-release-commits.sh"
    echo ""
    echo "🏷️  Current Versions:"
    echo "─────────────────────────────────────────────────────────────────"
    "$SCRIPT_DIR/check-versions.sh"
fi
