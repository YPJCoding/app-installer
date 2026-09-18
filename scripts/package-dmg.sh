#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
make -C "$ROOT_DIR" build

APP_PATH="$ROOT_DIR/build/App Installer.app"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$ROOT_DIR/.build/dmg"
DMG_PATH="$DIST_DIR/App-Installer-macOS13.dmg"

[[ -d "$APP_PATH" ]] || { echo "找不到应用: $APP_PATH" >&2; exit 1; }
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR" "$DIST_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/App Installer.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "App Installer" \
    -srcfolder "$STAGING_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"
echo "安装包: $DMG_PATH"
echo "校验文件: $DMG_PATH.sha256"
