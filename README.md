# CLI-Tools Repository

This repository contains CLI tools as submodules and embedded repositories, organized in the `Tools/` directory.

## Directory Structure

```
CLI-Tools/
├── Tools/                  # All CLI projects
│   ├── Advance-Commerce-CLI
│   ├── App-StoreKit-CLI
│   ├── Apple-Business-Connect-CLI
│   ├── Apple-Map-Server-CLI
│   ├── cli-template
│   ├── cimis-cli
│   ├── Google-Drive-CLI
│   ├── Google-Play-Developer-CLI
│   ├── Grokipedia-CLI
│   ├── Local-UniFi-CLI
│   ├── MyMarketNews-CLI
│   ├── UniFi-Site-Manager-CLI
│   ├── UPS-CLI
│   └── X-CLI
├── Skills/                 # Agent skills documentation (submodule)
├── homebrew-tap/           # Homebrew formulas (submodule)
└── .agents/               # Monorepo management scripts
```

## Submodules

- Advance-Commerce-CLI
- App-StoreKit-CLI
- Apple-Business-Connect-CLI
- Apple-Map-Server-CLI
- cli-template
- cimis-cli
- Google-Drive-CLI
- Google-Play-Developer-CLI
- Grokipedia-CLI
- Local-UniFi-CLI
- MyMarketNews-CLI
- Skills
- UniFi-Site-Manager-CLI
- UPS-CLI
- X-CLI
- homebrew-tap

## Getting Started

To clone with all submodules:
```bash
git clone --recursive https://github.com/dl-alexandre/CLI-Tools.git
```

To update all submodules:
```bash
git submodule update --init --recursive
```

