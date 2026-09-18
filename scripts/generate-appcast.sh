#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UPDATES_DIR="$ROOT_DIR/dist/updates"
TOOL="$ROOT_DIR/.build/artifacts/sparkle/Sparkle/bin/generate_appcast"
DOWNLOAD_PREFIX="https://github.com/YPJCoding/app-installer/releases/download/updates/"

[[ -x "$TOOL" ]] || {
    echo "找不到 generate_appcast，请先运行 swift package resolve。" >&2
    exit 1
}
[[ -d "$UPDATES_DIR" ]] || {
    echo "找不到更新包目录: $UPDATES_DIR" >&2
    exit 1
}

"$TOOL" \
    --download-url-prefix "$DOWNLOAD_PREFIX" \
    --maximum-versions 3 \
    "$UPDATES_DIR"

# GitHub normalizes spaces in release asset names, which breaks the URLs emitted
# by generate_appcast. Keep delta filenames URL-safe and update their references.
for delta_path in "$UPDATES_DIR"/*.delta(N); do
    delta_name="${delta_path:t}"
    safe_name="${delta_name// /-}"
    if [[ "$safe_name" != "$delta_name" ]]; then
        mv "$delta_path" "$UPDATES_DIR/$safe_name"
        encoded_name="${delta_name// /%20}"
        sed -i '' "s|$encoded_name|$safe_name|g" "$UPDATES_DIR/appcast.xml"
    fi
done

echo "Appcast: $UPDATES_DIR/appcast.xml"
