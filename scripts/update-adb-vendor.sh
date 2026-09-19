#!/bin/zsh
set -euo pipefail

[[ $# -eq 1 ]] || {
    echo "用法: update-adb-vendor.sh <Android platform-tools 目录>" >&2
    exit 2
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="${1:A}"
ADB_SOURCE="$SOURCE_DIR/adb"
NOTICE_SOURCE="$SOURCE_DIR/NOTICE.txt"
VENDOR_DIR="$ROOT_DIR/Vendor/macos13-universal"

[[ -x "$ADB_SOURCE" ]] || { echo "找不到可执行文件: $ADB_SOURCE" >&2; exit 1; }
[[ -f "$NOTICE_SOURCE" ]] || { echo "找不到声明文件: $NOTICE_SOURCE" >&2; exit 1; }

architectures="$(lipo -archs "$ADB_SOURCE")"
[[ "$architectures" == *arm64* && "$architectures" == *x86_64* ]] || {
    echo "adb 不是 Universal 2: $architectures" >&2
    exit 1
}

mkdir -p "$VENDOR_DIR/bin" "$VENDOR_DIR/licenses"
cp "$ADB_SOURCE" "$VENDOR_DIR/bin/adb"
chmod 755 "$VENDOR_DIR/bin/adb"
cp "$NOTICE_SOURCE" "$VENDOR_DIR/licenses/Android-SDK-Platform-Tools-NOTICE.txt"

"$VENDOR_DIR/bin/adb" version
shasum -a 256 "$VENDOR_DIR/bin/adb"
echo "ADB 与 NOTICE 已更新；请同步更新 Vendor/macos13-universal/README.md 中的版本和 SHA-256。"
