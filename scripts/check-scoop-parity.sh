#!/usr/bin/env bash
# check-scoop-parity.sh — Verify Scoop manifests cover the fleet and match formula versions.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlparse

root = Path(sys.argv[1])


def canonical_repo(url):
    """Normalize HTTPS and SSH GitHub URLs to owner/repository."""
    value = url.strip()
    match = re.match(r"git@github\.com:(.+)$", value)
    if match:
        value = "https://github.com/" + match.group(1)
    parsed = urlparse(value)
    if parsed.netloc.lower() != "github.com":
        return None
    path = parsed.path.strip("/")
    if path.endswith(".git"):
        path = path[:-4]
    return path.lower()


def git_config(key):
    result = subprocess.run(
        ["git", "-C", str(root), "config", "-f", ".gitmodules", "--get", key],
        capture_output=True, text=True,
    )
    return result.stdout.strip() if result.returncode == 0 else None


try:
    entries = subprocess.check_output(
        ["git", "-C", str(root), "config", "-f", ".gitmodules", "--get-regexp",
         r"^submodule\..*\.path$"], text=True,
    ).splitlines()
except (subprocess.CalledProcessError, FileNotFoundError) as error:
    print(f"❌ Could not read tool submodules from .gitmodules: {error}", file=sys.stderr)
    sys.exit(1)

tools = []
for entry in entries:
    key, path = entry.split(None, 1)
    path = path.strip()
    if not path.startswith("Tools/"):
        continue
    module = key.removesuffix(".path")
    repo = canonical_repo(git_config(module + ".url") or "")
    if not repo:
        print(f"❌ {path}: missing or unsupported GitHub URL in .gitmodules")
        sys.exit(1)
    tools.append((path, repo))

formulas = {}
for formula_path in sorted((root / "Formula").glob("*.rb")):
    content = formula_path.read_text()
    homepage = re.search(r'^\s*homepage\s+["\']([^"\']+)["\']', content, re.M)
    version = re.search(r'^\s*version\s+["\']([^"\']+)["\']', content, re.M)
    if homepage and version:
        formulas.setdefault(canonical_repo(homepage.group(1)), []).append(
            (formula_path.name, version.group(1))
        )

manifests = {}
for manifest_path in sorted((root / "scoop-bucket" / "bucket").glob("*.json")):
    try:
        manifest = json.loads(manifest_path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        print(f"❌ {manifest_path.name}: invalid JSON: {error}")
        sys.exit(1)
    repo = canonical_repo(manifest.get("homepage", ""))
    if repo:
        manifests.setdefault(repo, []).append((manifest_path.name, str(manifest.get("version", ""))))

errors = 0
checked = 0
for path, repo in tools:
    tool_name = Path(path).name
    if tool_name == "cli-template":
        print(f"ℹ️  {path}: intentionally omitted from Scoop (template repository)")
        continue

    matching_formulas = formulas.get(repo, [])
    matching_manifests = manifests.get(repo, [])
    if len(matching_formulas) != 1:
        print(f"❌ {path}: expected one formula for {repo}, found {len(matching_formulas)}")
        errors += 1
        continue
    if len(matching_manifests) != 1:
        print(f"❌ {path}: expected one Scoop manifest for {repo}, found {len(matching_manifests)}")
        errors += 1
        continue

    formula_name, formula_version = matching_formulas[0]
    manifest_name, manifest_version = matching_manifests[0]
    checked += 1
    if formula_version != manifest_version:
        print(
            f"❌ {path}: {manifest_name} version {manifest_version} does not match "
            f"{formula_name} version {formula_version}"
        )
        errors += 1
    else:
        print(f"✅ {path}: {manifest_name} matches {formula_name} at {formula_version}")

print("")
if errors:
    print(f"{errors} Scoop parity issue(s) found across {checked} checked tool(s).")
    sys.exit(1)

print(f"Scoop parity passed for all {checked} Scoop-supported tool(s).")
PY
