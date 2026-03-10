#!/bin/bash
# update-formulas.sh - Update homebrew formulas with latest release info
# Usage: ./update-formulas.sh

set -euo pipefail

TAP_DIR="${1:-/Users/developer/Documents/GitHub/workspaces/CLI-Tools/homebrew-tap}"
FORMULA_DIR="${TAP_DIR}/Formula"

echo "🔧 Updating Homebrew Formulas"
echo "=============================="
echo ""

# Define formulas and their repos
# Format: "formula_name:repo:binary_prefix"
declare -A FORMULAS=(
    ["abc"]="dl-alexandre/Apple-Business-Connect-CLI:abc"
    ["ams"]="dl-alexandre/Apple-Map-Server-CLI:ams"
    ["ask"]="dl-alexandre/App-StoreKit-CLI:ask"
    ["cimis"]="dl-alexandre/cimis-cli:cimis"
    ["cli-template"]="dl-alexandre/cli-template:cli-template"
    ["gdrv"]="dl-alexandre/Google-Drive-CLI:gdrv"
    ["gpd"]="dl-alexandre/Google-Play-Developer-CLI:gpd"
    ["mpr"]="dl-alexandre/MyMarketNews-CLI:mpr"
    ["unifi"]="dl-alexandre/Local-UniFi-CLI:unifi"
    ["usm"]="dl-alexandre/UniFi-Site-Manager-CLI:usm"
)

update_formula() {
    local formula=$1
    local repo=$2
    local binary=$3
    local formula_file="${FORMULA_DIR}/${formula}.rb"
    
    if [ ! -f "$formula_file" ]; then
        echo "⚠️  $formula: Formula file not found"
        return 1
    fi
    
    # Get latest release
    local latest_release=$(gh release list -R "$repo" --limit 1 --json tagName 2>/dev/null || echo '[]')
    local latest_version=$(echo "$latest_release" | jq -r '.[0].tagName // "none"')
    
    if [ "$latest_version" = "none" ]; then
        echo "⚠️  $formula: No releases found"
        return 1
    fi
    
    echo "📦 $formula: Updating to $latest_version"
    
    # Get release assets with SHA256
    local assets=$(gh release view "$latest_version" -R "$repo" --json assets 2>/dev/null || echo '{"assets":[]}')
    
    # Update version in formula
    sed -i '' "s/version \"[^\"]*\"/version \"${latest_version}\"/g" "$formula_file"
    sed -i '' "s/version \"[^\"]*\"/version \"${latest_version}\"/g" "$formula_file"
    
    # Update SHA256 values for each platform
    local platforms=("darwin_arm64" "darwin_x86_64" "linux_arm64" "linux_x86_64")
    local -A sha256s
    
    for platform in "${platforms[@]}"; do
        # Try to find asset for this platform
        local asset_name="${binary}_${latest_version#v}_${platform}.tar.gz"
        local sha256=$(echo "$assets" | jq -r ".assets[] | select(.name == \"$asset_name\") | .digest" | sed 's/sha256://' 2>/dev/null || echo "")
        
        if [ -n "$sha256" ]; then
            sha256s[$platform]="$sha256"
        fi
    done
    
    # Update SHA256s in formula file
    for platform in "${!sha256s[@]}"; do
        local sha256="${sha256s[$platform]}"
        local pattern="${platform}.*\.tar\.gz.*sha256.*TO_BE_UPDATED"
        if grep -q "$pattern" "$formula_file" 2>/dev/null; then
            sed -i '' "s/sha256 \"TO_BE_UPDATED\"/sha256 \"${sha256}\"/g" "$formula_file"
            echo "  ✓ Updated $platform: ${sha256:0:16}..."
        fi
    done
    
    echo "  ✅ Updated $formula"
}

# Update each formula
for formula_key in "${!FORMULAS[@]}"; do
    IFS=':' read -r repo binary <<< "${FORMULAS[$formula_key]}"
    update_formula "$formula_key" "$repo" "$binary" || true
    echo ""
done

echo "=============================="
echo "✅ Formula updates complete!"
echo ""
echo "Changed files:"
git -C "$TAP_DIR" diff --name-only 2>/dev/null || echo "  (none)"
