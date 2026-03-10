---
name: monorepo-cli
description: Monorepo management tools for CLI-Tools workspace. Use when checking CI status, release status, or versions across all 9 CLI projects. Scripts can check CI health, commits since last release, and current versions for each project.
---

# Monorepo CLI Management

This skill provides scripts to monitor and manage the 9 CLI projects in the monorepo.

## Projects Covered

1. **App-Store-Connect-CLI** (`asc`) - App Store Connect API
2. **Google-Drive-CLI** (`gdrv`) - Google Drive API
3. **Google-Play-Developer-CLI** (`gpd`) - Google Play Publishing
4. **grokipedia-cli** (`grokipedia`) - Wikipedia/Grok integration
5. **App-StoreKit-CLI** (`ask`) - App Store Kit API
6. **App-Store-Server-CLI** (`ass`) - App Store Server API
7. **Apple-Map-Server-CLI** (`ams`) - Apple Maps Server API
8. **MyMarketNews-CLI** (`mpr`) - USDA Market News
9. **cimis-cli** (`cimis`) - California Irrigation Management

## Available Scripts

Located in `.agents/skills/monorepo-cli/scripts/`:

### check-ci-status.sh
Check GitHub Actions CI status for all projects.

```bash
# Human-readable output
./.agents/skills/monorepo-cli/scripts/check-ci-status.sh

# JSON output
./.agents/skills/monorepo-cli/scripts/check-ci-status.sh --json
```

**Output:** Status emoji, project name, conclusion (success/failure), latest run title

### check-release-commits.sh
Check for commits beyond the latest release.

```bash
# Human-readable output
./.agents/skills/monorepo-cli/scripts/check-release-commits.sh

# JSON output
./.agents/skills/monorepo-cli/scripts/check-release-commits.sh --json
```

**Output:** Project name, latest release tag, number of commits since release

### check-versions.sh
Check current version of each project.

```bash
# Human-readable output
./.agents/skills/monorepo-cli/scripts/check-versions.sh

# JSON output
./.agents/skills/monorepo-cli/scripts/check-versions.sh --json
```

**Output:** Project name, current version (from git tag or GitHub release)

### monorepo-status.sh
Full dashboard combining all checks.

```bash
# Human-readable dashboard
./.agents/skills/monorepo-cli/scripts/monorepo-status.sh

# Combined JSON output
./.agents/skills/monorepo-cli/scripts/monorepo-status.sh --json
```

## Requirements

- `gh` CLI authenticated with GitHub (`gh auth status`)
- `jq` for JSON processing
- Access to all 9 GitHub repositories

## Usage Examples

**Quick CI check:**
```bash
./.agents/skills/monorepo-cli/scripts/check-ci-status.sh
```

**Check if releases are needed:**
```bash
./.agents/skills/monorepo-cli/scripts/check-release-commits.sh
```

**Full dashboard:**
```bash
./.agents/skills/monorepo-cli/scripts/monorepo-status.sh
```

**Parse with jq:**
```bash
./.agents/skills/monorepo-cli/scripts/monorepo-status.sh --json | jq '.ci_status[] | select(.conclusion == "failure")'
```
