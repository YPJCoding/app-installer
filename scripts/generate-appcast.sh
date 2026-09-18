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

echo "Appcast: $UPDATES_DIR/appcast.xml"
