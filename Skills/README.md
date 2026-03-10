# CLI Tools Skills

A collection of Agent Skills for all CLI tools in the monorepo. These skills provide zero-friction automation guidance for:

- **App Store Connect** (`asc`) - App Store Connect API
- **Google Drive** (`gdrv`) - Google Drive API  
- **Google Play Developer** (`gpd`) - Google Play Publishing
- **UniFi Site Manager** (`usm`) - UniFi cloud site management
- **Local UniFi** (`unifi`) - Local UniFi Controller API
- **MyMarketNews** (`mpr`) - USDA commodity data
- **California Irrigation** (`cimis`) - CIMIS weather data
- **Apple Map Server** (`ams`) - Apple Maps Server API
- **App StoreKit** (`ask`) - App Store Kit API
- **App Store Server** (`ass`) - App Store Server API
- **Monorepo** (`monorepo-cli`) - Cross-project management

Skills follow the Agent Skills format.

## Available Skills

### App Store Connect (asc)

#### asc-cli-usage
Guidance for running `asc` commands (flags, pagination, output, auth).

**Use when:**
- You need the correct `asc` command or flag combination
- You want JSON-first output and pagination tips for automation

#### asc-workflow
Define and run repo-local automation graphs using `asc workflow` and `.asc/workflow.json`.

**Use when:**
- You are migrating from lane-based automation to repo-local workflows
- You need multi-step orchestration with machine-parseable JSON output for CI/agents
- You need hooks (`before_all`, `after_all`, `error`), conditionals (`if`), and private helper sub-workflows
- You want validation (`asc workflow validate`) with cycle/reference checks before execution

#### asc-app-create-ui
Create a new App Store Connect app via browser automation when no API exists.

**Use when:**
- You need to create an app record (name, bundle ID, SKU, primary language)
- You are comfortable logging in to App Store Connect in a real browser

#### asc-xcode-build
Build, archive, and export iOS/macOS apps with xcodebuild before uploading.

**Use when:**
- You need to create an IPA or PKG for upload
- You're setting up CI/CD build pipelines
- You need to configure ExportOptions.plist
- You're troubleshooting encryption compliance issues

#### asc-shots-pipeline
Agent-first screenshot pipeline using xcodebuild/simctl, AXe, JSON plans, `asc screenshots frame` (experimental), and `asc screenshots upload`.

**Use when:**
- You need a repeatable simulator screenshot automation flow
- You want AXe-based UI driving before capture
- You need a staged pipeline (capture -> frame -> upload)
- You need to discover supported frame devices (`asc screenshots list-frame-devices`)
- You want pinned Koubou guidance for deterministic framing (`koubou==0.13.0`)

#### asc-release-flow
End-to-end release workflows for TestFlight and App Store.

**Use when:**
- You want to upload, distribute, and submit in one flow
- You need the manual sequence for fine-grained control
- You're releasing for iOS, macOS, visionOS, or tvOS

#### asc-signing-setup
Bundle IDs, capabilities, certificates, and provisioning profiles.

**Use when:**
- You are onboarding a new app or bundle ID
- You need to create or rotate signing assets

#### asc-id-resolver
Resolve IDs for apps, builds, versions, groups, and testers.

**Use when:**
- A command requires IDs and you only have names
- You want deterministic outputs for automation

#### asc-metadata-sync
Metadata and localization sync (including legacy metadata format migration).

**Use when:**
- You are updating App Store metadata or localizations
- You need to validate character limits before upload
- You need to update privacy policy URL or app-level metadata

#### asc-localize-metadata
Translate App Store metadata (description, keywords, what's new, subtitle) to multiple locales using LLM translation prompts and push via `asc`.

**Use when:**
- You want to localize an app's App Store listing from a source locale (usually en-US)
- You need locale-aware keywords (not literal translations) and strict character limit enforcement
- You want a review-before-upload workflow for translations

#### asc-submission-health
Preflight checks, submission, and review monitoring.

**Use when:**
- You want to reduce submission failures
- You need to track review status and re-submit safely
- You're troubleshooting "version not in valid state" errors

#### asc-testflight-orchestration
Beta groups, testers, build distribution, and What to Test notes.

**Use when:**
- You manage multiple TestFlight groups and testers
- You need consistent beta rollout steps

#### asc-build-lifecycle
Build processing, latest build resolution, and cleanup.

**Use when:**
- You are waiting on build processing
- You want automated cleanup and retention policies

#### asc-ppp-pricing
Territory-specific pricing using purchasing power parity (PPP).

**Use when:**
- You want different prices for different countries
- You are implementing localized pricing strategies
- You need to adjust prices based on regional purchasing power

#### asc-subscription-localization
Bulk-localize subscription and IAP display names across all App Store locales.

**Use when:**
- You want to set the same subscription display name in every language at once
- You need to fill in missing subscription/group/IAP localizations
- You're tired of clicking through each locale in App Store Connect manually

#### asc-notarization
Archive, export, and notarize macOS apps with Developer ID signing.

**Use when:**
- You need to notarize a macOS app for distribution outside the App Store
- You want the full flow: archive → Developer ID export → zip → notarize → staple
- You're troubleshooting Developer ID signing or trust chain issues

---

### Google Play Developer (gpd)

#### gpd-cli
Google Play Developer CLI usage and authentication.

**Use when:**
- You need to publish Android apps to Google Play
- You're managing Play Console operations programmatically
- You need to upload APKs/AABs, create releases, or manage tracks

#### gpd-cli-usage
Guidance for running `gpd` commands.

**Use when:**
- You need the correct `gpd` command syntax
- You want to understand flags and options

#### gpd-metadata-sync
Sync app metadata and listings to Google Play.

**Use when:**
- You need to update app descriptions, screenshots, or store listings
- You're localizing app listings for different countries

#### gpd-release-flow
End-to-end release workflows for Google Play.

**Use when:**
- You want to upload, promote, and release in one flow
- You need to manage internal, alpha, beta, and production tracks

#### gpd-betagroups
Beta testing groups and testers management.

**Use when:**
- You manage beta testers
- You need to add/remove testers from groups

#### gpd-id-resolver
Resolve IDs for apps, tracks, and releases.

**Use when:**
- A command requires IDs and you only have names
- You want deterministic outputs for automation

#### gpd-build-lifecycle
Build upload, processing, and management.

**Use when:**
- You are uploading AAB/APK files
- You need to check processing status

#### gpd-ppp-pricing
Territory-specific pricing for Google Play.

**Use when:**
- You want different prices for different countries
- You are implementing localized pricing strategies

#### gpd-submission-health
Preflight checks and submission monitoring.

**Use when:**
- You want to reduce submission failures
- You need to validate app bundles before upload

---

### Google Drive (gdrv)

#### gdrv-cli
Google Drive CLI for file management.

**Use when:**
- You need to upload/download files to/from Google Drive
- You're managing Drive files programmatically
- You need to share files or manage permissions

---

### UniFi Site Manager (usm)

#### usm-cli
UniFi Site Manager CLI for cloud-based site management.

**Use when:**
- You need to monitor UniFi sites across multiple locations
- You want to list sites and devices via the cloud API
- You're managing UniFi deployments at scale

**Key commands:**
- `usm init` - Setup configuration
- `usm sites list` - List all sites with filtering
- `usm sites get <id>` - Get specific site details
- `usm whoami` - Verify authentication

**Authentication:**
- API key from unifi.ui.com (Settings → Control Plane → Integrations → API Keys)
- Environment variable: `USM_API_KEY`
- Never stored in config file

---

### Local UniFi Controller (unifi)

#### unifi-cli
Local UniFi Controller CLI for on-premise network management.

**Use when:**
- You need to manage a local UniFi Controller (Dream Machine, Cloud Key, self-hosted)
- You want to list sites, devices, and clients directly from the controller
- You're troubleshooting network issues locally

**Key commands:**
- `unifi init` - Setup configuration
- `unifi sites list` - List all sites on controller
- `unifi devices list` - List all UniFi devices (APs, switches, gateways)
- `unifi clients list` - List connected clients

**Authentication:**
- Local admin account (not cloud/SSO)
- Environment variables: `UNIFI_USERNAME`, `UNIFI_PASSWORD`
- Session-based auth handled automatically

---

### Monorepo CLI Management (monorepo-cli)

#### monorepo-cli
Cross-project management for the CLI tools monorepo.

**Use when:**
- You need to check CI status across all 9 projects
- You want to see which projects have commits since last release
- You're managing releases across multiple CLIs

**Available scripts:**
- `check-ci-status.sh` - Check GitHub Actions CI status
- `check-release-commits.sh` - Commits beyond latest release
- `check-versions.sh` - Current versions
- `monorepo-status.sh` - Full dashboard

---

## Installation

Install individual skills or the entire skill pack:

```bash
# Install all skills
npx skills add dl-alexandre/Skills

# Or specific skills only
npx skills add dl-alexandre/Skills --include asc-cli-usage,asc-release-flow
```

## Usage

Skills are automatically available once installed. The agent will use them when relevant tasks are detected.

**Examples:**

```
Build and upload my iOS app to App Store Connect
```

```
Publish my Android app version 1.2.3 to Google Play production track
```

```
List all my UniFi sites and export to JSON
```

```
Check CI status for all CLI projects in the monorepo
```

```
Upload file backup.zip to Google Drive folder Backups
```

## Skill Structure

Each skill contains:
- `SKILL.md` - Instructions for the agent
- `scripts/` - Helper scripts for automation (optional)
- `references/` - Supporting documentation (optional)

## Available CLIs

| CLI | Repository | Description |
|-----|------------|-------------|
| `asc` | App-Store-Connect-CLI | App Store Connect API |
| `gdrv` | Google-Drive-CLI | Google Drive API |
| `gpd` | Google-Play-Developer-CLI | Google Play Publishing |
| `usm` | UniFi-Site-Manager-CLI | UniFi cloud site management |
| `unifi` | Local-UniFi-CLI | Local UniFi Controller API |
| `mpr` | MyMarketNews-CLI | USDA commodity data |
| `cimis` | cimis-cli | CIMIS weather data |
| `ams` | Apple-Map-Server-CLI | Apple Maps Server API |
| `ask` | App-StoreKit-CLI | App Store Kit API |
| `ass` | App-Store-Server-CLI | App Store Server API |

## License

MIT
