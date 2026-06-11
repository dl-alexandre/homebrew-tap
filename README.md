# CLI Tools Fleet

Meta-repository for the dl-alexandre CLI tool fleet: Homebrew tap, Scoop bucket, shared library, skills, and 14 Go CLI tools as git submodules.

## Structure

| Path | Purpose |
|------|---------|
| `Formula/` | Homebrew tap formulas (single source of truth for `brew tap dl-alexandre/tap`) |
| `scoop-bucket/` | Scoop bucket submodule |
| `cli-tools/` | Shared Go library submodule |
| `Skills/` | Agent skills submodule |
| `Tools/*` | Individual CLI tool repositories (14 tools + `cli-template`) |
| `scripts/` | Fleet maintenance, health checks, and formula automation |

## CLI Tools

| Formula | Tool | Description |
|---------|------|-------------|
| [`abc`](https://github.com/dl-alexandre/Apple-Business-Connect-CLI) | Apple-Business-Connect-CLI | Apple Business Connect CLI |
| [`aca`](https://github.com/dl-alexandre/Advance-Commerce-CLI) | Advance-Commerce-CLI | Advanced Commerce API CLI |
| [`ams`](https://github.com/dl-alexandre/Apple-Map-Server-CLI) | Apple-Map-Server-CLI | Apple Map Server CLI |
| [`ask`](https://github.com/dl-alexandre/App-StoreKit-CLI) | App-StoreKit-CLI | App StoreKit CLI |
| [`cimis`](https://github.com/dl-alexandre/cimis-cli) | cimis-cli | California Irrigation Management CLI |
| [`cli-template`](https://github.com/dl-alexandre/cli-template) | cli-template | Go CLI template / reference implementation |
| [`gdrv`](https://github.com/dl-alexandre/Google-Drive-CLI) | Google-Drive-CLI | Google Drive CLI |
| [`gpd`](https://github.com/dl-alexandre/Google-Play-Developer-CLI) | Google-Play-Developer-CLI | Google Play Developer CLI |
| [`grokipedia`](https://github.com/dl-alexandre/Grokipedia-CLI) | Grokipedia-CLI | Grokipedia API CLI |
| [`mpr`](https://github.com/dl-alexandre/MyMarketNews-CLI) | MyMarketNews-CLI | USDA MyMarketNews CLI |
| [`unifi`](https://github.com/dl-alexandre/Local-UniFi-CLI) | Local-UniFi-CLI | Local UniFi Controller CLI |
| [`ups`](https://github.com/dl-alexandre/UPS-CLI) | UPS-CLI | UPS shipping CLI |
| [`usm`](https://github.com/dl-alexandre/UniFi-Site-Manager-CLI) | UniFi-Site-Manager-CLI | UniFi Site Manager CLI |
| [`x-cli`](https://github.com/dl-alexandre/X-CLI) | X-CLI | X/Twitter CLI (binary release; `x.rb` is a source-build fallback) |

## Install

```bash
brew tap dl-alexandre/tap
brew install <formula>
```

See each tool's repository for usage documentation.

## Automation

### Formula updates

The `update-formulas` workflow auto-discovers every `Formula/*.rb` file, reads the GitHub repo from each formula's `homepage`, and opens a PR when a new release is published. No hardcoded tool list — add a formula file and it is included automatically.

### Fleet maintenance

- `scripts/refresh-dependencies.sh` — normalize Go workflow setup, refresh modules, tidy, and test
- `scripts/check-submodule-pointers.sh` — compare submodule gitlinks with `.gitmodules` branches (`--update` to fast-forward)
- `scripts/check-formula-coverage.sh` — verify every `Tools/*` submodule has a matching formula
- `scripts/check-template-drift.sh` — verify every tool matches the `cli-template` baseline (README, LICENSE, Makefile, CI + release workflows, GoReleaser config, golangci-lint v2 config) and flags `go.mod` Go version outliers
- `scripts/check-ci-health.sh` / `scripts/check-releases.sh` — fleet-wide CI and release audits
- Dependabot grouping for GitHub Actions, Go modules, and submodule updates

### Fleet health CI

The weekly `fleet-health` workflow runs CI health checks, release audits, formula coverage validation, and template drift detection.

### Fleet baseline policy

Every tool tracks `Tools/cli-template`: standard Makefile targets, `ci.yml` (test + golangci-lint v2) and `release.yml` (GoReleaser on tag push) workflows, and the shared `.golangci.yml` baseline (govet, staticcheck, errcheck, ineffassign, unused, misspell, unparam, errorlint). Tools should stay on the fleet's common `go` directive; `scripts/refresh-dependencies.sh` handles version bumps fleet-wide rather than per-tool drift.

## Development

### GoReleaser configuration

See [GoReleaser Configuration Guide](docs/GORELEASER_GUIDE.md) for the build configuration needed to integrate with formula automation.

### Token permissions

The `TAP_TOKEN` secret requires:
- `contents:write` — create branches and commit formula updates
- `pull_requests:write` — create pull requests with formula updates