#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UNIVERSAL_DIR="$ROOT_DIR/Vendor/macos13-universal"

valid_tool() {
    local arch="$1" tool="$2"
    local path="$ROOT_DIR/Vendor/macos13-$arch/bin/$tool"
    [[ -x "$path" ]] || return 1
    lipo -archs "$path" | grep -qw "$arch" || return 1
    [[ "$(vtool -show-build "$path" | awk '/minos/{print $2}' | sort -Vu)" == "13.0" ]]
}

for arch in arm64 x86_64; do
    if ! valid_tool "$arch" idevice_id || ! valid_tool "$arch" ideviceinstaller; then
        "$ROOT_DIR/scripts/build-ios-tools-macos13.sh" "$arch"
    fi
done

mkdir -p "$UNIVERSAL_DIR/bin" "$UNIVERSAL_DIR/licenses"
rm -f "$UNIVERSAL_DIR/bin/idevice_id" "$UNIVERSAL_DIR/bin/ideviceinstaller"
find "$UNIVERSAL_DIR/licenses" -type f \
    ! -name 'Android-SDK-Platform-Tools-NOTICE.txt' -delete
for tool in idevice_id ideviceinstaller; do
    lipo -create \
        "$ROOT_DIR/Vendor/macos13-arm64/bin/$tool" \
        "$ROOT_DIR/Vendor/macos13-x86_64/bin/$tool" \
        -output "$UNIVERSAL_DIR/bin/$tool"
    chmod 755 "$UNIVERSAL_DIR/bin/$tool"
done
cp "$ROOT_DIR/Vendor/macos13-arm64/licenses/"* "$UNIVERSAL_DIR/licenses/"

for tool in idevice_id ideviceinstaller; do
    architectures="$(lipo -archs "$UNIVERSAL_DIR/bin/$tool")"
    [[ "$architectures" == *arm64* && "$architectures" == *x86_64* ]] || {
        echo "$tool 不是 Universal 2: $architectures" >&2; exit 1
    }
    minos="$(vtool -show-build "$UNIVERSAL_DIR/bin/$tool" | awk '/minos/{print $2}' | sort -Vu)"
    [[ "$minos" == "13.0" ]] || { echo "$tool 最低版本错误: $minos" >&2; exit 1; }
done

echo "Universal 2 iOS 工具构建完成: $UNIVERSAL_DIR"
