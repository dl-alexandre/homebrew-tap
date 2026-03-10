---
name: monorepo-cli
description: Monorepo management tools for CLI-Tools workspace. Use when checking status of all CLI projects, submodules, and embedded repositories. Scripts check CI status, versions, and sync state across local repos, GitHub repos, and submodules.
---

# Monorepo CLI Management

This skill provides scripts to monitor and manage all CLI projects in the monorepo - including GitHub repos, local embedded repos, and submodules.

## Directory Structure

All CLI tools are organized in the `Tools/` directory:

```
CLI-Tools/
├── Tools/                  # All CLI projects
│   ├── Advance-Commerce-CLI
│   ├── App-StoreKit-CLI
│   ├── Apple-Business-Connect-CLI
│   ├── ... (13 total CLI projects)
├── Skills/                 # Agent skills documentation (submodule)
├── homebrew-tap/           # Homebrew formulas (submodule)
└── .agents/               # Monorepo management scripts
```

## Repository Types

### GitHub Repos (External)
- **App-StoreKit-CLI** (`ask`) - App Store Kit API
- **X-CLI** (`x`) - X/Twitter CLI (submodule)
- **homebrew-tap** - Homebrew formulas (submodule)

### Embedded Git Repositories
- **Advance-Commerce-CLI** - Advance Commerce API
- **App-StoreKit-CLI** - App Store Kit API
- **Apple-Business-Connect-CLI** - Apple Business Connect
- **Apple-Map-Server-CLI** - Apple Maps Server API
- **cli-template** - Go CLI template
- **Google-Drive-CLI** - Google Drive API
- **Google-Play-Developer-CLI** - Google Play Publishing
- **Grokipedia-CLI** - Wikipedia/Grok integration
- **Local-UniFi-CLI** - Local UniFi controller
- **MyMarketNews-CLI** - USDA Market News
- **UniFi-Site-Manager-CLI** - UniFi Site Manager
- **UPS-CLI** - UPS API integration
- **cimis-cli** - California Irrigation Management

### Submodules
- **Skills** - CLI skills documentation
- **X-CLI** - X/Twitter CLI
- **homebrew-tap** - Homebrew tap

## Available Scripts

Located in `.agents/skills/monorepo-cli/scripts/`:

### check-status.sh
Comprehensive status check for all repository types.

```bash
# Human-readable output
./.agents/skills/monorepo-cli/scripts/check-status.sh

# JSON output
./.agents/skills/monorepo-cli/scripts/check-status.sh --json

# Check specific types only
./.agents/skills/monorepo-cli/scripts/check-status.sh --embedded
./.agents/skills/monorepo-cli/scripts/check-status.sh --submodules
./.agents/skills/monorepo-cli/scripts/check-status.sh --github
```

**Output:**
- Git status (dirty/clean, ahead/behind)
- Last commit date
- Branch name
- Uncommitted changes count
- Submodule sync status

### check-versions.sh
Check current versions across all projects.

```bash
# Human-readable output
./.agents/skills/monorepo-cli/scripts/check-versions.sh

# JSON output
./.agents/skills/monorepo-cli/scripts/check-versions.sh --json
```

**Output:** Project name, version (from git tag or module)

### sync-check.sh
Check if submodules are synced and up to date.

```bash
./.agents/skills/monorepo-cli/scripts/sync-check.sh
```

**Output:** Submodule path, current commit, expected commit, sync status

### check-tap-versions.sh
Check if homebrew formulas match the latest GitHub releases.

```bash
# Check all formulas against latest releases
./.agents/skills/monorepo-cli/scripts/check-tap-versions.sh

# Shows outdated formulas with current vs latest versions
```

**Output:** Formula name, current version, latest release, SHA256 status

### monorepo-status.sh
Full dashboard combining all checks.

```bash
# Human-readable dashboard
./.agents/skills/monorepo-cli/scripts/monorepo-status.sh

# Combined JSON output
./.agents/skills/monorepo-cli/scripts/monorepo-status.sh --json

# Focus on issues only
./.agents/skills/monorepo-cli/scripts/monorepo-status.sh --issues
```

## Requirements

- `git` (obviously)
- `gh` CLI authenticated with GitHub (`gh auth status`) - for GitHub repos only
- `jq` for JSON processing (optional, for --json output)

## Usage Examples

**Quick status of everything:**
```bash
./.agents/skills/monorepo-cli/scripts/check-status.sh
```

**Check if submodules need updating:**
```bash
./.agents/skills/monorepo-cli/scripts/sync-check.sh
```

**See only projects with issues:**
```bash
./.agents/skills/monorepo-cli/scripts/monorepo-status.sh --issues
```

**Update all submodules:**
```bash
git submodule update --init --recursive
git submodule update --remote --merge
```

**Full dashboard:**
```bash
./.agents/skills/monorepo-cli/scripts/monorepo-status.sh
```

## Common Workflows

### Daily Check
```bash
# Quick check for any issues
./.agents/skills/monorepo-cli/scripts/monorepo-status.sh --issues
```

### Before Committing
```bash
# Check all embedded repos are clean
./.agents/skills/monorepo-cli/scripts/check-status.sh --embedded
```

### Release Preparation
```bash
# Check versions and sync status
./.agents/skills/monorepo-cli/scripts/monorepo-status.sh
```
