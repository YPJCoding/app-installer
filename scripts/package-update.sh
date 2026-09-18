#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/version.env"

make -C "$ROOT_DIR" build

APP_PATH="$ROOT_DIR/build/App Installer.app"
UPDATES_DIR="$ROOT_DIR/dist/updates"
ARCHIVE_NAME="App-Installer-$APP_VERSION.zip"
ARCHIVE_PATH="$UPDATES_DIR/$ARCHIVE_NAME"

mkdir -p "$UPDATES_DIR"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ARCHIVE_PATH"

echo "Sparkle 更新包: $ARCHIVE_PATH"
