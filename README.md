# Homebrew Tap

Automated Homebrew tap for dl-alexandre CLI tools. This repository automatically updates formulas when new releases are published.

## Available Formulas

| Formula | Description |
|---------|-------------|
| [`abc`](https://github.com/dl-alexandre/Apple-Business-Connect-CLI) | Apple Business Connect CLI |
| [`ams`](https://github.com/dl-alexandre/Apple-Map-Server-CLI) | Apple Map Server CLI |
| [`ask`](https://github.com/dl-alexandre/App-StoreKit-CLI) | App StoreKit CLI |
| [`cimis`](https://github.com/dl-alexandre/cimis-cli) | California Irrigation Management CLI |
| [`cli-template`](https://github.com/dl-alexandre/cli-template) | Go CLI Template (example/template CLI) |
| [`gdrv`](https://github.com/dl-alexandre/Google-Drive-CLI) | Google Drive CLI |
| [`gpd`](https://github.com/dl-alexandre/Google-Play-Developer-CLI) | Google Play Developer CLI |
| [`mpr`](https://github.com/dl-alexandre/MyMarketNews-CLI) | USDA MyMarketNews CLI |
| [`unifi`](https://github.com/dl-alexandre/Local-UniFi-CLI) | Local UniFi Controller CLI |
| [`usm`](https://github.com/dl-alexandre/UniFi-Site-Manager-CLI) | UniFi Site Manager CLI |

## Install

```bash
brew tap dl-alexandre/tap
brew install <formula>
```

See each formula's repository for usage documentation.

## Automation

This tap uses a Ruby-based GitHub Actions workflow to:
- Check for new releases daily at 00:00 UTC
- Calculate SHA256 hashes for all platform binaries
- Create Pull Requests with updated formulas
- Test formulas on both macOS and Linux before merging

Dependency and submodule maintenance are handled with:
- `scripts/refresh-dependencies.sh` to normalize Go workflow setup, refresh every Go module, tidy module files, and run tests.
- `scripts/check-submodule-pointers.sh` to compare parent gitlinks with the branch configured in `.gitmodules`; pass `--update` to fast-forward and stage pointer changes.
- Dependabot grouping for GitHub Actions, Go modules, and parent `gitsubmodule` updates to reduce single-package PR noise.

## Development

### GoReleaser Configuration

If you're developing a CLI tool for this tap, see [GoReleaser Configuration Guide](docs/GORELEASER_GUIDE.md) for the exact build configuration needed to integrate with our automation.

### Token Permissions

The `TAP_TOKEN` secret requires:
- `contents:write` - To create branches and commit formula updates
- `pull_requests:write` - To create pull requests with formula updates
