#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${1:-}"

case "$ARCH" in
    arm64)
        BUILD_TARGET="build-arm64"
        BUILD_FOLDER="arm64"
        DMG_NAME="App-Installer-macOS13-arm64.dmg"
        ;;
    intel|x86_64)
        BUILD_TARGET="build-intel"
        BUILD_FOLDER="intel"
        DMG_NAME="App-Installer-macOS13-intel.dmg"
        ;;
    universal)
        BUILD_TARGET="build-universal"
        BUILD_FOLDER="universal"
        DMG_NAME="App-Installer-macOS13-universal.dmg"
        ;;
    *)
        echo "用法: ./scripts/package-dmg.sh arm64|intel|universal" >&2
        exit 2
        ;;
esac

make -C "$ROOT_DIR" "$BUILD_TARGET"

APP_PATH="$ROOT_DIR/build/$BUILD_FOLDER/App Installer.app"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$ROOT_DIR/.build/dmg-$BUILD_FOLDER"
DMG_PATH="$DIST_DIR/$DMG_NAME"

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
