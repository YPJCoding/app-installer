#!/bin/zsh
set -euo pipefail

[[ $# -eq 1 ]] || { echo "用法: embed-tools.sh <目标 Tools 目录>" >&2; exit 2; }

TOOLS_DIR="$1"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/Vendor/macos13-universal"
BIN_DIR="$TOOLS_DIR/bin"
LIB_DIR="$TOOLS_DIR/lib"
LICENSE_DIR="$TOOLS_DIR/licenses"
rm -rf "$TOOLS_DIR"
mkdir -p "$BIN_DIR" "$LIB_DIR" "$LICENSE_DIR"

locate_tool() {
    local name="$1"
    local candidate
    for candidate in "$VENDOR_DIR/bin/$name" "/opt/homebrew/bin/$name" "/usr/local/bin/$name" "$HOME/Library/Android/sdk/platform-tools/$name"; do
        if [[ -x "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

for name in adb idevice_id ideviceinstaller; do
    source_path="$(locate_tool "$name" || true)"
    [[ -n "$source_path" ]] || {
        echo "缺少 $name。请先安装构建依赖后再打包。" >&2
        echo "  brew install android-platform-tools libimobiledevice ideviceinstaller" >&2
        exit 1
    }
    cp -L "$source_path" "$BIN_DIR/$name"
    chmod 755 "$BIN_DIR/$name"
done

for bundled_tool in adb idevice_id ideviceinstaller; do
    architectures="$(lipo -archs "$BIN_DIR/$bundled_tool")"
    [[ "$architectures" == *arm64* && "$architectures" == *x86_64* ]] || {
        echo "$bundled_tool 不是 Universal 2: $architectures" >&2
        exit 1
    }
done

for ios_tool in idevice_id ideviceinstaller; do
    minos="$(vtool -show-build "$BIN_DIR/$ios_tool" | awk '/minos/{print $2}' | sort -Vu)"
    [[ "$minos" == "13.0" ]] || {
        echo "$ios_tool 的最低系统版本是 $minos，不是 13.0。" >&2
        echo "请先运行 ./scripts/build-ios-tools-universal.sh" >&2
        exit 1
    }
done

# Homebrew 的 iOS 工具依赖多组动态库。递归复制，并改成 App 内相对路径。
queue=("$BIN_DIR/idevice_id" "$BIN_DIR/ideviceinstaller")
index=1
while (( index <= ${#queue[@]} )); do
    target="${queue[$index]}"
    (( index += 1 ))
    dependencies=("${(@f)$(otool -L "$target" | tail -n +2 | awk '{print $1}' | grep -E '^/(opt/homebrew|usr/local)/' || true)}")
    for dependency in "${dependencies[@]}"; do
        [[ -n "$dependency" ]] || continue
        filename="${dependency:t}"
        destination="$LIB_DIR/$filename"
        if [[ ! -f "$destination" ]]; then
            cp -L "$dependency" "$destination"
            chmod 755 "$destination"
            queue+=("$destination")
        fi
        if [[ "$target" == "$BIN_DIR/"* ]]; then
            replacement="@loader_path/../lib/$filename"
        else
            replacement="@loader_path/$filename"
        fi
        install_name_tool -change "$dependency" "$replacement" "$target"
    done
done

for library in "$LIB_DIR"/*.dylib(N); do
    install_name_tool -id "@loader_path/${library:t}" "$library"
done

adb_source="$(locate_tool adb)"
if [[ -L "$adb_source" ]]; then
    adb_source="$(readlink "$adb_source")"
fi
adb_notice="${adb_source:h}/NOTICE.txt"
[[ -f "$adb_notice" ]] && cp "$adb_notice" "$LICENSE_DIR/Android-SDK-Platform-Tools-NOTICE.txt"

# 将所有实际或间接依赖的许可证随 App 一起交付；不依赖网络下载。
if [[ -d "$VENDOR_DIR/licenses" ]]; then
    cp "$VENDOR_DIR/licenses/"* "$LICENSE_DIR/"
fi
for formula in libimobiledevice ideviceinstaller libplist libimobiledevice-glue libusbmuxd libzip openssl@3 xz zstd; do
    prefix="$(brew --prefix "$formula" 2>/dev/null || true)"
    [[ -n "$prefix" ]] || continue
    for license in "$prefix"/COPYING*(N) "$prefix"/LICENSE*(N); do
        cp "$license" "$LICENSE_DIR/${formula//\@/-}-${license:t}"
    done
done

cat > "$LICENSE_DIR/README.txt" <<'EOF'
App Installer bundles Android SDK Platform-Tools (adb) and components from the
libimobiledevice ecosystem. See the accompanying notice/license files. The
corresponding upstream projects and source code are available from:

https://developer.android.com/tools/releases/platform-tools
https://github.com/libimobiledevice/libimobiledevice
https://github.com/libimobiledevice/ideviceinstaller

Additional dynamically linked libraries retain their respective licenses.
Run `otool -L` on Tools/lib files to audit the packaged dependency set.
EOF

echo "已嵌入工具：$(du -sh "$TOOLS_DIR" | awk '{print $1}')"
