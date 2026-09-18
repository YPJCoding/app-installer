#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/version.env"
BUILD_DIR="$ROOT_DIR/build"
BUILD_MODE="${1:-universal}"
case "$BUILD_MODE" in
    universal) OUTPUT_DIR="$BUILD_DIR/universal" ;;
    arm64) OUTPUT_DIR="$BUILD_DIR/arm64" ;;
    x86_64|intel) BUILD_MODE="x86_64"; OUTPUT_DIR="$BUILD_DIR/intel" ;;
    *) echo "用法: ./App/build.sh [universal|arm64|intel]" >&2; exit 2 ;;
esac
APP_DIR="$OUTPUT_DIR/App Installer.app"
CONTENTS_DIR="$APP_DIR/Contents"
SIGN_IDENTITY="${APP_IDENTITY:--}"

cd "$ROOT_DIR"
swift build

rm -rf "$APP_DIR"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources" "$CONTENTS_DIR/Frameworks"
if [[ "$BUILD_MODE" == "universal" ]]; then
    swift build -c release --arch arm64 --scratch-path .build/release-arm64
    swift build -c release --arch x86_64 --scratch-path .build/release-x86_64
    ARM_BIN_DIR="$(swift build -c release --arch arm64 --scratch-path .build/release-arm64 --show-bin-path)"
    INTEL_BIN_DIR="$(swift build -c release --arch x86_64 --scratch-path .build/release-x86_64 --show-bin-path)"
    lipo -create "$ARM_BIN_DIR/AppInstaller" "$INTEL_BIN_DIR/AppInstaller" \
        -output "$CONTENTS_DIR/MacOS/AppInstaller"
else
    SCRATCH_PATH=".build/release-$BUILD_MODE"
    swift build -c release --arch "$BUILD_MODE" --scratch-path "$SCRATCH_PATH"
    BIN_DIR="$(swift build -c release --arch "$BUILD_MODE" --scratch-path "$SCRATCH_PATH" --show-bin-path)"
    cp "$BIN_DIR/AppInstaller" "$CONTENTS_DIR/MacOS/AppInstaller"
fi
chmod 755 "$CONTENTS_DIR/MacOS/AppInstaller"
SPARKLE_FRAMEWORK_SOURCE="${ARM_BIN_DIR:-$BIN_DIR}/Sparkle.framework"
[[ -d "$SPARKLE_FRAMEWORK_SOURCE" ]] || {
    echo "找不到 Sparkle.framework: $SPARKLE_FRAMEWORK_SOURCE" >&2
    exit 1
}
ditto "$SPARKLE_FRAMEWORK_SOURCE" "$CONTENTS_DIR/Frameworks/Sparkle.framework"
cp "$ROOT_DIR/App/Info.plist" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$CONTENTS_DIR/Info.plist"
cp -R "$ROOT_DIR/App/Resources/." "$CONTENTS_DIR/Resources/"
printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"
"$ROOT_DIR/scripts/embed-tools.sh" "$CONTENTS_DIR/Resources/Tools" "$BUILD_MODE"

find "$CONTENTS_DIR/Resources/Tools" -type f \( -perm -111 -o -name '*.dylib' \) -print0 | while IFS= read -r -d '' item; do
    # 内嵌命令行工具是独立子进程。开发用 ad-hoc 签名不启用 hardened
    # runtime，否则其动态库会因没有 Developer ID Team ID 而被拒绝加载。
    if [[ "$SIGN_IDENTITY" == "-" ]]; then
        codesign --force --sign - "$item"
    else
        codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$item"
    fi
done
if [[ "$SIGN_IDENTITY" == "-" ]]; then
    codesign --force --deep --sign - "$CONTENTS_DIR/Frameworks/Sparkle.framework"
    codesign --force --deep --options runtime \
        --entitlements "$ROOT_DIR/App/Development.entitlements" --sign - "$APP_DIR"
else
    codesign --force --deep --options runtime --timestamp \
        --sign "$SIGN_IDENTITY" "$CONTENTS_DIR/Frameworks/Sparkle.framework"
    codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
fi
codesign --verify --deep --strict --verbose=2 "$APP_DIR"
echo "$APP_DIR"
