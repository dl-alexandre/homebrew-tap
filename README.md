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
| [`x-cli`](https://github.com/dl-alexandre/X-CLI) | X-CLI | X/Twitter CLI |

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

- `scripts/refresh-dependencies.sh` — normalize Go workflow setup, refresh package and test dependencies, tidy, and test; report any failed step
- `scripts/check-submodule-pointers.sh` — compare submodule gitlinks with `.gitmodules` branches (`--update` to fast-forward)
- `scripts/check-formula-coverage.sh` — verify every `Tools/*` submodule has a matching formula
- `scripts/check-scoop-parity.sh` — verify every Scoop-supported tool has a manifest whose version matches its Homebrew formula (`cli-template` is intentionally omitted)
- `scripts/check-template-drift.sh` — verify every tool matches the `cli-template` baseline (README, LICENSE, Makefile, CI + release workflows, GoReleaser config, golangci-lint v2 config) and flags `go.mod` Go version outliers
- `scripts/check-ci-health.sh` / `scripts/check-releases.sh` — fleet-wide CI and release audits
- `python3 scripts/tests/test_health_checks.py` — regression checks for health reports, including API failures and tap workflows
- Dependabot grouping for GitHub Actions, Go modules, and submodule updates

### Fleet health CI

The weekly `fleet-health` workflow runs CI health checks, release audits, formula coverage and Scoop parity validation, and template drift detection.

### Fleet baseline policy

Every tool tracks `Tools/cli-template`: standard Makefile targets, `ci.yml` (test + golangci-lint v2) and `release.yml` (GoReleaser on tag push) workflows, and the shared `.golangci.yml` baseline (govet, staticcheck, errcheck, ineffassign, unused, misspell, unparam, errorlint). Tools should stay on the fleet's common `go` directive; `scripts/refresh-dependencies.sh` handles version bumps fleet-wide rather than per-tool drift.

## Development

### GoReleaser configuration

See [GoReleaser Configuration Guide](docs/GORELEASER_GUIDE.md) for the build configuration needed to integrate with formula automation.

### Automation token

Scheduled workflows need a token that reaches this tap and every fleet repository, including private tool repositories. They get it from a **GitHub App** that mints a fresh one-hour token on every run, so there is nothing to renew:

1. Create a GitHub App (Settings > Developer settings > GitHub Apps > New), for example `dl-alexandre-tap-bot`. Disable the webhook and grant these **repository** permissions:
   - Contents: read and write — branches, formula commits, releases
   - Pull requests: read and write — formula update PRs
   - Actions: read — fleet CI health
   - Metadata: read (always on)

   Nothing else: the tracking issue is filed with the built-in `GITHUB_TOKEN`.
2. Generate a private key, then install the app on this tap and every fleet repository (or on all repositories).
3. In this repository's Settings > Secrets and variables > Actions, add the **variable** `TAP_APP_CLIENT_ID` (the app's Client ID; the numeric App ID as `TAP_APP_ID` also works) and the **secret** `TAP_APP_PRIVATE_KEY` (the full `.pem` contents).

Each job mints its token with `actions/create-github-app-token`. PRs opened with it trigger CI, unlike PRs opened with the built-in `GITHUB_TOKEN`. The preflight job in each scheduled workflow (`scripts/check-token.py`) fails fast and keeps one tracking issue open if the app token cannot be minted or cannot read the tap.

**Legacy fallback:** while neither `TAP_APP_CLIENT_ID` nor `TAP_APP_ID` is set, the workflows fall back to the `TAP_TOKEN` personal access token secret (classic `repo` + `workflow` scopes, or fine-grained with contents, pull requests, and Actions access to every fleet repository). The preflight warns 14 days before it expires; a `401 Bad credentials` means it must be replaced. Once the app has run successfully, delete the `TAP_TOKEN` secret.

The health scripts report inaccessible repositories as failures; with the app, that usually means it is not installed on that repository.
