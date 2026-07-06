# CLI-Tools Dependencies Audit

Last refreshed: 2026-06-24.

This document tracks Go dependencies used across the CLI-Tools monorepo. The curated sections capture human audit decisions for notable dependencies. The generated inventory captures the exact `require` surface in `cli-tools/go.mod` and `Tools/*/go.mod`.

## Legend
- ⭐ **Starred** - Repository starred on GitHub
- ✅ **Current** - Using latest version reported by `go list -m -json <module>@latest`
- ⚠️ **Update Available** - Newer version exists
- 🔍 **Needs Review** - Need to verify if still needed
- 🗑️ **Remove / Not Present** - Not currently required by any audited `go.mod`
- **Direct** - `require` entry not marked `// indirect`
- **Indirect-only** - Only required through `// indirect` entries

## Audit Method

Inventory was generated from the 15 module files under `cli-tools/go.mod` and `Tools/*/go.mod` with `go mod edit -json`. Latest-version checks in curated rows were verified with `go list -m -json <module>@latest`.

Current inventory counts:

| Count | Value |
|-------|-------|
| Total `require` entries | 408 |
| Unique required module paths | 143 |
| Direct `require` entries | 111 |
| Unique direct module paths | 46 |
| Unique indirect-only module paths | 97 |

The previously reported "116 missing dependencies" maps to the full unique `require` inventory, not just Go direct dependencies: the old hand audit listed about 27 rows, while `go.mod` files currently require 143 unique module paths.

Regeneration command:

```sh
for mod in $(find cli-tools Tools -name go.mod -not -path '*/.git/*' | sort); do
  dir=${mod%/go.mod}
  (cd "$dir" && go mod edit -json) | jq -c --arg project "$dir" \
    '.Require[] | {path:.Path, project:$project, version:.Version, indirect:(.Indirect // false)}'
done
```

## Core Dependencies

### CLI Frameworks

| Repository | Direct Usage | Current Version | Latest Version | Status | Notes |
|------------|--------------|-----------------|----------------|--------|-------|
| ⭐ [alecthomas/kong](https://github.com/alecthomas/kong) | 11 projects | v1.15.0 | v1.15.0 | ✅ | Primary CLI framework |
| [spf13/cobra](https://github.com/spf13/cobra) | 4 projects | v1.10.2 | v1.10.2 | ✅ | Alternative CLI framework in legacy/newer app-specific projects |
| ⭐ [spf13/viper](https://github.com/spf13/viper) | 9 projects | v1.21.0 | v1.21.0 | ✅ | Config management |

### Security & Authentication

| Repository | Direct Usage | Current Version | Latest Version | Status | Notes |
|------------|--------------|-----------------|----------------|--------|-------|
| ⭐ [zalando/go-keyring](https://github.com/zalando/go-keyring) | 3 projects | v0.2.8 | v0.2.8 | ✅ | Secure credential storage |
| [99designs/keyring](https://github.com/99designs/keyring) | 1 project | v1.2.2 | v1.2.2 | 🔍 | Used by Google-Play-Developer-CLI; keep unless auth storage is intentionally standardized |
| [golang-jwt/jwt](https://github.com/golang-jwt/jwt) | 2 projects | v5.3.1 | v5.3.1 | ✅ | JWT handling for App Store / commerce APIs |
| [refraction-networking/utls](https://github.com/refraction-networking/utls) | 1 project | v1.8.2 | v1.8.2 | ✅ | **Required**: TLS fingerprinting for X API bot-detection avoidance |
| [golang.org/x/oauth2](https://pkg.go.dev/golang.org/x/oauth2) | 2 projects | v0.36.0 | v0.36.0 | ✅ | OAuth flows for Google CLIs |

### HTTP Clients & Browser Automation

| Repository | Direct Usage | Current Version | Latest Version | Status | Notes |
|------------|--------------|-----------------|----------------|--------|-------|
| ⭐ [go-resty/resty](https://github.com/go-resty/resty) | 6 projects | v2.17.2 | v2.17.2 | ✅ | Primary HTTP client |
| ⭐ [chromedp/chromedp](https://github.com/chromedp/chromedp) | 1 project | v0.15.1 | v0.15.1 | ✅ | Browser automation for X-CLI OAuth |
| [chromedp/cdproto](https://github.com/chromedp/cdproto) | 1 project | v0.0.0-20260427013145-5737772c319b | v0.0.0-20260427013145-5737772c319b | ✅ | Chrome DevTools Protocol bindings paired with chromedp |

### Output, Formatting & TUI

| Repository | Direct Usage | Current Version | Latest Version | Status | Notes |
|------------|--------------|-----------------|----------------|--------|-------|
| [rodaine/table](https://github.com/rodaine/table) | 8 projects | v1.3.1 | v1.3.1 | ✅ | Primary table formatting |
| [mattn/go-isatty](https://github.com/mattn/go-isatty) | 8 projects | v0.0.22 | v0.0.22 | ✅ | Terminal detection |
| [olekukonko/tablewriter](https://github.com/olekukonko/tablewriter) | 2 projects | v1.1.4 | v1.1.4 | ✅ | Table rendering in Apple-Map-Server-CLI and Google-Drive-CLI |
| ⭐ [charmbracelet/lipgloss](https://github.com/charmbracelet/lipgloss) | 1 project | v1.1.0 | v1.1.0 | ✅ | Google-Drive-CLI TUI styling |
| [charmbracelet/bubbletea](https://github.com/charmbracelet/bubbletea) | 1 project | v1.3.10 | v1.3.10 | ✅ | Google-Drive-CLI TUI runtime; imported by `internal/tui` and `internal/cli/tui.go` |
| [jedib0t/go-pretty](https://github.com/jedib0t/go-pretty) | 1 project | v6.8.1 | v6.8.1 | ✅ | Pretty printing in App-StoreKit-CLI |
| [schollz/progressbar](https://github.com/schollz/progressbar) | 2 projects | v3.19.0 | v3.19.0 | ✅ | Progress bars |

### Data Processing

| Repository | Direct Usage | Current Version | Latest Version | Status | Notes |
|------------|--------------|-----------------|----------------|--------|-------|
| [gocarina/gocsv](https://github.com/gocarina/gocsv) | 1 project | v0.0.0-20240520201108-78e41c74b4b1 | v0.0.0-20260607070740-0735908c6461 | ⚠️ | CSV handling in Apple-Business-Connect-CLI |
| [xuri/excelize](https://github.com/xuri/excelize) | 1 project | v2.10.1 | v2.10.1 | ✅ | Excel handling in Google-Play-Developer-CLI |
| [google/uuid](https://github.com/google/uuid) | 2 projects | v1.6.0 | v1.6.0 | ✅ | UUID generation |
| [itchyny/gojq](https://github.com/itchyny/gojq) | 1 project | v0.12.19 | v0.12.19 | ✅ | JSON querying in App-StoreKit-CLI |
| [google.golang.org/api](https://pkg.go.dev/google.golang.org/api) | 2 projects | v0.284.0, v0.285.0 | v0.286.0 | ⚠️ | Google APIs in Google-Drive-CLI and Google-Play-Developer-CLI |

### Utilities

| Repository | Direct Usage | Current Version | Latest Version | Status | Notes |
|------------|--------------|-----------------|----------------|--------|-------|
| [sahilm/fuzzy](https://github.com/sahilm/fuzzy) | 1 project | v0.1.3 | v0.1.3 | ✅ | Fuzzy matching in Google-Drive-CLI |
| [skip2/go-qrcode](https://github.com/skip2/go-qrcode) | 1 project | v0.0.0-20200617195104-da1b6568686e | v0.0.0-20200617195104-da1b6568686e | ✅ | QR code generation in Google-Drive-CLI |
| [pkg/browser](https://github.com/pkg/browser) | 1 project | v0.0.0-20240102092130-5ac0b6a4141c | v0.0.0-20240102092130-5ac0b6a4141c | ✅ | Open browser for OAuth flows |
| [jotaen/kong-completion](https://github.com/jotaen/kong-completion) | 1 project | v0.0.14 | v0.0.14 | ✅ | Shell completions for kong in X-CLI |

### Testing

| Repository | Direct Usage | Current Version | Latest Version | Status | Notes |
|------------|--------------|-----------------|----------------|--------|-------|
| [stretchr/testify](https://github.com/stretchr/testify) | 1 direct project | v1.11.1 | v1.11.1 | ✅ | Test assertions; also appears indirectly in one module |

### Not Present

| Repository | Status | Notes |
|------------|--------|-------|
| [browserutils/kooky](https://github.com/browserutils/kooky) | 🗑️ | No current `go.mod` requirement or import found under `cli-tools` or `Tools/*`; removed from active dependency audit rows |

## Generated Direct Dependency Inventory

This table is generated from exact non-`// indirect` `require` entries. `github.com/dl-alexandre/*` rows are first-party module requirements and are included for inventory completeness.

| Module | Version(s) | Direct Projects |
|--------|------------|-----------------|
| `cloud.google.com/go/ai` | v1.0.0 | Tools/Google-Drive-CLI |
| `cloud.google.com/go/apps` | v1.0.0 | Tools/Google-Drive-CLI |
| `cloud.google.com/go/iam` | v1.11.0 | Tools/Google-Drive-CLI |
| `cloud.google.com/go/logging` | v1.18.0 | Tools/Google-Drive-CLI |
| `cloud.google.com/go/longrunning` | v1.0.0 | Tools/Google-Drive-CLI |
| `cloud.google.com/go/monitoring` | v1.29.0 | Tools/Google-Drive-CLI |
| `github.com/99designs/keyring` | v1.2.2 | Tools/Google-Play-Developer-CLI |
| `github.com/alecthomas/kong` | v1.15.0 | Tools/Apple-Business-Connect-CLI, Tools/Google-Drive-CLI, Tools/Google-Play-Developer-CLI, Tools/Grokipedia-CLI, Tools/Local-UniFi-CLI, Tools/MyMarketNews-CLI, Tools/UPS-CLI, Tools/UniFi-Site-Manager-CLI, Tools/X-CLI, Tools/cli-template, cli-tools |
| `github.com/charmbracelet/bubbletea` | v1.3.10 | Tools/Google-Drive-CLI |
| `github.com/charmbracelet/lipgloss` | v1.1.0 | Tools/Google-Drive-CLI |
| `github.com/chromedp/cdproto` | v0.0.0-20260427013145-5737772c319b | Tools/X-CLI |
| `github.com/chromedp/chromedp` | v0.15.1 | Tools/X-CLI |
| `github.com/dl-alexandre/cimis-tsdb` | v1.0.0 | Tools/cimis-cli |
| `github.com/dl-alexandre/cli-tools` | v0.0.1 | Tools/App-StoreKit-CLI, Tools/Google-Drive-CLI, Tools/Grokipedia-CLI, Tools/Local-UniFi-CLI, Tools/MyMarketNews-CLI, Tools/UPS-CLI, Tools/UniFi-Site-Manager-CLI, Tools/X-CLI, Tools/cimis-cli, Tools/cli-template |
| `github.com/go-resty/resty/v2` | v2.17.2 | Tools/Apple-Business-Connect-CLI, Tools/Grokipedia-CLI, Tools/Local-UniFi-CLI, Tools/UPS-CLI, Tools/UniFi-Site-Manager-CLI, Tools/cli-template |
| `github.com/gocarina/gocsv` | v0.0.0-20240520201108-78e41c74b4b1 | Tools/Apple-Business-Connect-CLI |
| `github.com/golang-jwt/jwt/v5` | v5.3.1 | Tools/Advance-Commerce-CLI, Tools/App-StoreKit-CLI |
| `github.com/google/uuid` | v1.6.0 | Tools/Advance-Commerce-CLI, Tools/Google-Drive-CLI |
| `github.com/itchyny/gojq` | v0.12.19 | Tools/App-StoreKit-CLI |
| `github.com/jedib0t/go-pretty/v6` | v6.8.1 | Tools/App-StoreKit-CLI |
| `github.com/jotaen/kong-completion` | v0.0.14 | Tools/X-CLI |
| `github.com/mattn/go-isatty` | v0.0.22 | Tools/Apple-Business-Connect-CLI, Tools/Grokipedia-CLI, Tools/Local-UniFi-CLI, Tools/UPS-CLI, Tools/UniFi-Site-Manager-CLI, Tools/X-CLI, Tools/cli-template, cli-tools |
| `github.com/olekukonko/tablewriter` | v1.1.4 | Tools/Apple-Map-Server-CLI, Tools/Google-Drive-CLI |
| `github.com/pkg/browser` | v0.0.0-20240102092130-5ac0b6a4141c | Tools/Google-Play-Developer-CLI |
| `github.com/refraction-networking/utls` | v1.8.2 | Tools/X-CLI |
| `github.com/rodaine/table` | v1.3.1 | Tools/Apple-Business-Connect-CLI, Tools/Grokipedia-CLI, Tools/Local-UniFi-CLI, Tools/UPS-CLI, Tools/UniFi-Site-Manager-CLI, Tools/X-CLI, Tools/cli-template, cli-tools |
| `github.com/sahilm/fuzzy` | v0.1.3 | Tools/Google-Drive-CLI |
| `github.com/schollz/progressbar/v3` | v3.19.0 | Tools/Apple-Map-Server-CLI, Tools/Google-Drive-CLI |
| `github.com/skip2/go-qrcode` | v0.0.0-20200617195104-da1b6568686e | Tools/Google-Drive-CLI |
| `github.com/spf13/cobra` | v1.10.2 | Tools/Advance-Commerce-CLI, Tools/App-StoreKit-CLI, Tools/Grokipedia-CLI, Tools/MyMarketNews-CLI |
| `github.com/spf13/viper` | v1.21.0 | Tools/App-StoreKit-CLI, Tools/Apple-Business-Connect-CLI, Tools/Grokipedia-CLI, Tools/Local-UniFi-CLI, Tools/UPS-CLI, Tools/UniFi-Site-Manager-CLI, Tools/X-CLI, Tools/cli-template, cli-tools |
| `github.com/stretchr/testify` | v1.11.1 | Tools/UniFi-Site-Manager-CLI |
| `github.com/xuri/excelize/v2` | v2.10.1 | Tools/Google-Play-Developer-CLI |
| `github.com/zalando/go-keyring` | v0.2.8 | Tools/Apple-Business-Connect-CLI, Tools/Google-Drive-CLI, Tools/X-CLI |
| `golang.org/x/oauth2` | v0.36.0 | Tools/Google-Drive-CLI, Tools/Google-Play-Developer-CLI |
| `golang.org/x/sync` | v0.21.0 | Tools/Google-Play-Developer-CLI |
| `golang.org/x/term` | v0.44.0 | Tools/Apple-Map-Server-CLI, Tools/Local-UniFi-CLI |
| `golang.org/x/text` | v0.38.0 | Tools/Apple-Business-Connect-CLI, Tools/Google-Drive-CLI, Tools/Google-Play-Developer-CLI, Tools/X-CLI |
| `google.golang.org/api` | v0.284.0, v0.285.0 | Tools/Google-Drive-CLI, Tools/Google-Play-Developer-CLI |
| `google.golang.org/genproto` | v0.0.0-20260504160031-60b97b32f348 | Tools/Google-Drive-CLI |
| `google.golang.org/genproto/googleapis/api` | v0.0.0-20260504160031-60b97b32f348 | Tools/Google-Drive-CLI |
| `google.golang.org/genproto/googleapis/rpc` | v0.0.0-20260610212136-7ab31c22f7ad | Tools/Google-Drive-CLI |
| `google.golang.org/grpc` | v1.83.0-dev | Tools/Google-Drive-CLI |
| `google.golang.org/protobuf` | v1.36.11 | Tools/Google-Drive-CLI |
| `gopkg.in/yaml.v3` | v3.0.1 | Tools/App-StoreKit-CLI, Tools/Apple-Map-Server-CLI, Tools/Google-Drive-CLI, Tools/Google-Play-Developer-CLI, Tools/Grokipedia-CLI |
| `modernc.org/sqlite` | v1.53.0 | Tools/Google-Drive-CLI |

## Generated Indirect-only Requirement Inventory

These modules are present only as `// indirect` requirements in the audited `go.mod` files. They are listed for drift detection, but normally do not need starring or manual audit unless code starts importing them directly.

| Module | Version(s) | Module Count |
|--------|------------|--------------|
| `cloud.google.com/go` | v0.123.0 | 1 |
| `cloud.google.com/go/auth` | v0.20.0 | 2 |
| `cloud.google.com/go/auth/oauth2adapt` | v0.2.8 | 2 |
| `cloud.google.com/go/compute/metadata` | v0.9.0 | 2 |
| `github.com/99designs/go-keychain` | v0.0.0-20191008050251-8e49817e8af4 | 1 |
| `github.com/andybalholm/brotli` | v1.2.1 | 1 |
| `github.com/aymanbagabas/go-osc52/v2` | v2.0.1 | 1 |
| `github.com/cespare/xxhash/v2` | v2.3.0 | 3 |
| `github.com/charmbracelet/colorprofile` | v0.4.3 | 1 |
| `github.com/charmbracelet/x/ansi` | v0.11.7 | 1 |
| `github.com/charmbracelet/x/cellbuf` | v0.0.15 | 1 |
| `github.com/charmbracelet/x/term` | v0.2.2 | 1 |
| `github.com/chengxilo/virtualterm` | v1.0.5 | 2 |
| `github.com/chromedp/sysutil` | v1.1.0 | 1 |
| `github.com/clipperhouse/displaywidth` | v0.11.0 | 2 |
| `github.com/clipperhouse/uax29/v2` | v2.7.0 | 11 |
| `github.com/danieljoos/wincred` | v1.2.3 | 4 |
| `github.com/davecgh/go-spew` | v1.1.1, v1.1.2-0.20180830191138-d8f796af33cc | 3 |
| `github.com/dustin/go-humanize` | v1.0.1 | 1 |
| `github.com/dvsekhvalnov/jose2go` | v1.8.0 | 1 |
| `github.com/erikgeiser/coninput` | v0.0.0-20211004153227-1c3628e74d0f | 1 |
| `github.com/fatih/color` | v1.19.0 | 2 |
| `github.com/felixge/httpsnoop` | v1.0.4 | 2 |
| `github.com/fsnotify/fsnotify` | v1.10.1 | 9 |
| `github.com/go-json-experiment/json` | v0.0.0-20260430182902-b6187a392ed4 | 1 |
| `github.com/go-logr/logr` | v1.4.3 | 2 |
| `github.com/go-logr/stdr` | v1.2.2 | 2 |
| `github.com/go-viper/mapstructure/v2` | v2.5.0 | 9 |
| `github.com/gobwas/httphead` | v0.1.0 | 1 |
| `github.com/gobwas/pool` | v0.2.1 | 1 |
| `github.com/gobwas/ws` | v1.4.0 | 1 |
| `github.com/goccy/go-json` | v0.10.6 | 2 |
| `github.com/godbus/dbus` | v0.0.0-20190726142602-4481cbc300e2 | 1 |
| `github.com/godbus/dbus/v5` | v5.2.2 | 3 |
| `github.com/google/pprof` | v0.0.0-20260402051712-545e8a4df936 | 1 |
| `github.com/google/s2a-go` | v0.1.9 | 2 |
| `github.com/googleapis/enterprise-certificate-proxy` | v0.3.16 | 2 |
| `github.com/googleapis/gax-go/v2` | v2.22.0 | 2 |
| `github.com/gsterjov/go-libsecret` | v0.0.0-20161001094733-a6f4afe4910c | 1 |
| `github.com/hashicorp/errwrap` | v1.1.0 | 1 |
| `github.com/hashicorp/go-multierror` | v1.1.1 | 1 |
| `github.com/inconshreveable/mousetrap` | v1.1.0 | 4 |
| `github.com/itchyny/timefmt-go` | v0.1.8 | 1 |
| `github.com/klauspost/compress` | v1.18.6 | 2 |
| `github.com/ledongthuc/pdf` | v0.0.0-20250511090121-5959a4027728 | 1 |
| `github.com/lucasb-eyer/go-colorful` | v1.4.0 | 1 |
| `github.com/mattn/go-colorable` | v0.1.14 | 2 |
| `github.com/mattn/go-localereader` | v0.0.1 | 1 |
| `github.com/mattn/go-runewidth` | v0.0.23 | 11 |
| `github.com/mattn/go-sqlite3` | v1.14.44 | 1 |
| `github.com/mitchellh/colorstring` | v0.0.0-20190213212951-d06e56a500db | 2 |
| `github.com/mtibben/percent` | v0.2.1 | 1 |
| `github.com/muesli/ansi` | v0.0.0-20230316100256-276c6243b2f6 | 1 |
| `github.com/muesli/cancelreader` | v0.2.2 | 1 |
| `github.com/muesli/termenv` | v0.16.0 | 1 |
| `github.com/ncruces/go-strftime` | v1.0.0 | 1 |
| `github.com/olekukonko/cat` | v0.0.0-20250911104152-50322a0618f6 | 2 |
| `github.com/olekukonko/errors` | v1.3.0 | 2 |
| `github.com/olekukonko/ll` | v0.1.8 | 2 |
| `github.com/orisano/pixelmatch` | v0.0.0-20230914042517-fa304d1dc785 | 1 |
| `github.com/pelletier/go-toml/v2` | v2.3.1 | 9 |
| `github.com/pmezard/go-difflib` | v1.0.0, v1.0.1-0.20181226105442-5d4384ee4fb2 | 3 |
| `github.com/posener/complete` | v1.2.3 | 1 |
| `github.com/remyoudompheng/bigfft` | v0.0.0-20230129092748-24d4a6f8daec | 1 |
| `github.com/richardlehane/mscfb` | v1.0.6 | 1 |
| `github.com/richardlehane/msoleps` | v1.0.6 | 1 |
| `github.com/rivo/uniseg` | v0.4.7 | 2 |
| `github.com/riywo/loginshell` | v0.0.0-20200815045211-7d26008be1ab | 1 |
| `github.com/rogpeppe/go-internal` | v1.14.1 | 9 |
| `github.com/sagikazarmark/locafero` | v0.12.0 | 9 |
| `github.com/spf13/afero` | v1.15.0 | 9 |
| `github.com/spf13/cast` | v1.10.0 | 9 |
| `github.com/spf13/pflag` | v1.0.10 | 11 |
| `github.com/stretchr/objx` | v0.5.3 | 5 |
| `github.com/subosito/gotenv` | v1.6.0 | 9 |
| `github.com/tiendc/go-deepcopy` | v1.7.2 | 1 |
| `github.com/xo/terminfo` | v0.0.0-20220910002029-abceb7e1c41e | 1 |
| `github.com/xuri/efp` | v0.0.1 | 1 |
| `github.com/xuri/nfp` | v0.0.2-0.20250530014748-2ddeb826f9a9 | 1 |
| `github.com/xyproto/randomstring` | v1.2.0 | 1 |
| `go.opentelemetry.io/auto/sdk` | v1.2.1 | 2 |
| `go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc` | v0.68.0 | 1 |
| `go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp` | v0.68.0 | 2 |
| `go.opentelemetry.io/otel` | v1.43.0 | 2 |
| `go.opentelemetry.io/otel/metric` | v1.43.0 | 2 |
| `go.opentelemetry.io/otel/trace` | v1.43.0 | 2 |
| `go.yaml.in/yaml/v3` | v3.0.4 | 9 |
| `golang.org/x/crypto` | v0.50.0, v0.51.0, v0.53.0 | 3 |
| `golang.org/x/exp` | v0.0.0-20260410095643-746e56fc9e2f | 1 |
| `golang.org/x/image` | v0.39.0 | 1 |
| `golang.org/x/net` | v0.53.0, v0.54.0, v0.55.0, v0.56.0 | 8 |
| `golang.org/x/sys` | v0.43.0, v0.44.0, v0.45.0, v0.46.0 | 12 |
| `golang.org/x/time` | v0.15.0 | 7 |
| `gopkg.in/check.v1` | v1.0.0-20201130134442-10cb98267c6c | 10 |
| `modernc.org/libc` | v1.73.4 | 1 |
| `modernc.org/mathutil` | v1.7.1 | 1 |
| `modernc.org/memory` | v1.11.0 | 1 |

## Action Items

### Immediate
1. Keep Dependabot grouped for Go modules and GitHub Actions across CLI repos.
2. Regenerate this inventory after dependency updates using the command in **Audit Method**.
3. Run `scripts/refresh-dependencies.sh` only for an intentional all-repo dependency refresh.
4. Run `scripts/check-submodule-pointers.sh --update` only after child repo updates merge, then commit the staged parent gitlinks.

### Consolidation Candidates (Deferred)

After review, we decided **not** to consolidate these libraries:

**Table Libraries (rodaine vs olekukonko vs go-pretty)**
- **Decision:** Keep all three
- **Rationale:** Different feature sets are used by different CLIs; migration cost across projects outweighs cleanup value while the libraries remain stable.

**Keyring Libraries (zalando vs 99designs)**
- **Decision:** Keep both
- **Rationale:** `99designs/keyring` remains isolated to Google-Play-Developer-CLI, while `zalando/go-keyring` is used by three projects. Standardization can wait until auth storage is actively touched.

### For Starring

After audit, star these high-impact repos if not already starred:
1. alecthomas/kong
2. zalando/go-keyring
3. chromedp/chromedp
4. go-resty/resty
5. spf13/viper
6. charmbracelet/* ecosystem if Google-Drive-CLI TUI investment continues

## Changelog

- **2026-06-24** - Refreshed dependency audit from `go.mod` files; corrected stale current/latest rows; marked `browserutils/kooky` not present; corrected `charmbracelet/bubbletea` as an active Google-Drive-CLI dependency; added generated direct and indirect-only requirement inventories.
- **2026-05-04** - Added grouped Dependabot configs for Go modules, GitHub Actions, and parent submodule updates; normalized Go CI workflows to read from `go.mod`; added maintenance scripts for dependency refreshes and submodule pointer checks.
- **2026-03-30** - Earlier audit recorded attempted kong/viper, chromedp, and table dependency refresh work; current version state is superseded by the 2026-06-24 generated inventory above.
- **2026-03-30** - Starred 6 high-impact dependencies after audit
- **2026-03-30** - Initial dependency audit document created
- Next review: 2026-09-30 (quarterly)

---

**Note:** Update this document whenever dependencies are added, updated, removed, or newly starred.
