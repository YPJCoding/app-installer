#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/version.env"

: "${APP_IDENTITY:?请设置 APP_IDENTITY（Developer ID Application 证书名称）}"
: "${NOTARY_PROFILE:?请设置 NOTARY_PROFILE（notarytool 钥匙串配置名）}"

APP_IDENTITY="$APP_IDENTITY" make -C "$ROOT_DIR" build-universal

APP_PATH="$ROOT_DIR/build/universal/App Installer.app"
UPDATES_DIR="$ROOT_DIR/dist/updates"
ARCHIVE_PATH="$UPDATES_DIR/App-Installer-$APP_VERSION.zip"
SUBMISSION_PATH="$ROOT_DIR/.build/App-Installer-notarization.zip"

mkdir -p "$UPDATES_DIR" "$ROOT_DIR/.build"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$SUBMISSION_PATH"
xcrun notarytool submit "$SUBMISSION_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ARCHIVE_PATH"
"$ROOT_DIR/scripts/generate-appcast.sh"

echo "已签名、公证并生成 Sparkle 发布文件: $UPDATES_DIR"
