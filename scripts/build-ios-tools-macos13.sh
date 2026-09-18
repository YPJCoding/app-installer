#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${1:-arm64}"
[[ "$ARCH" == "arm64" || "$ARCH" == "x86_64" ]] || { echo "架构必须是 arm64 或 x86_64" >&2; exit 2; }
WORK_DIR="$ROOT_DIR/.build/ios-tools-macos13-$ARCH"
SOURCE_DIR="$WORK_DIR/sources"
PREFIX="$ROOT_DIR/Vendor/macos13-$ARCH"
DOWNLOAD_DIR="$WORK_DIR/downloads"
DEPLOYMENT_TARGET="13.0"

export MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET"
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
export PATH="/opt/homebrew/opt/libtool/libexec/gnubin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export CC="$(xcrun --find clang)"
export CXX="$(xcrun --find clang++)"
export CFLAGS="-O2 -arch $ARCH -mmacosx-version-min=$DEPLOYMENT_TARGET"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -arch $ARCH -mmacosx-version-min=$DEPLOYMENT_TARGET"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"

mkdir -p "$SOURCE_DIR" "$DOWNLOAD_DIR"
rm -rf "$PREFIX"
mkdir -p "$PREFIX"

fetch_extract() {
    local name="$1"
    local url="$2"
    local archive="$DOWNLOAD_DIR/${url:t}"
    [[ -f "$archive" ]] || curl --fail --location --show-error "$url" --output "$archive"
    rm -rf "$SOURCE_DIR/$name"
    mkdir -p "$SOURCE_DIR/$name"
    tar -xf "$archive" -C "$SOURCE_DIR/$name" --strip-components=1
}

build_autotools() {
    local name="$1"
    shift
    local build="$WORK_DIR/build-$name"
    rm -rf "$build"
    mkdir -p "$build"
    cd "$build"
    "$SOURCE_DIR/$name/configure" \
        --prefix="$PREFIX" --disable-shared --enable-static "$@"
    make -j"$(sysctl -n hw.ncpu)"
    make install
}

fetch_extract openssl https://github.com/openssl/openssl/releases/download/openssl-3.6.4/openssl-3.6.4.tar.gz
cd "$SOURCE_DIR/openssl"
OPENSSL_TARGET="darwin64-arm64-cc"
[[ "$ARCH" == "x86_64" ]] && OPENSSL_TARGET="darwin64-x86_64-cc"
./Configure "$OPENSSL_TARGET" no-shared no-tests \
    --prefix="$PREFIX" --openssldir="$PREFIX/etc/ssl" \
    "-mmacosx-version-min=$DEPLOYMENT_TARGET"
make -j"$(sysctl -n hw.ncpu)"
make install_sw

fetch_extract libplist https://github.com/libimobiledevice/libplist/releases/download/2.7.0/libplist-2.7.0.tar.bz2
build_autotools libplist --without-cython

fetch_extract libimobiledevice-glue https://github.com/libimobiledevice/libimobiledevice-glue/releases/download/1.3.2/libimobiledevice-glue-1.3.2.tar.bz2
build_autotools libimobiledevice-glue

fetch_extract libtatsu https://github.com/libimobiledevice/libtatsu/releases/download/1.0.5/libtatsu-1.0.5.tar.bz2
build_autotools libtatsu

fetch_extract libusbmuxd https://github.com/libimobiledevice/libusbmuxd/releases/download/2.1.1/libusbmuxd-2.1.1.tar.bz2
build_autotools libusbmuxd

fetch_extract libimobiledevice https://github.com/libimobiledevice/libimobiledevice/releases/download/1.4.0/libimobiledevice-1.4.0.tar.bz2
build_autotools libimobiledevice --without-cython

fetch_extract libzip https://libzip.org/download/libzip-1.11.4.tar.xz
rm -rf "$WORK_DIR/build-libzip"
cmake -S "$SOURCE_DIR/libzip" -B "$WORK_DIR/build-libzip" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
    -DBUILD_SHARED_LIBS=OFF -DBUILD_TOOLS=OFF -DBUILD_REGRESS=OFF \
    -DBUILD_EXAMPLES=OFF -DBUILD_DOC=OFF \
    -DENABLE_BZIP2=OFF -DENABLE_LZMA=OFF -DENABLE_ZSTD=OFF -DENABLE_OPENSSL=OFF
cmake --build "$WORK_DIR/build-libzip" --parallel "$(sysctl -n hw.ncpu)"
cmake --install "$WORK_DIR/build-libzip"

fetch_extract ideviceinstaller https://github.com/libimobiledevice/ideviceinstaller/releases/download/1.2.0/ideviceinstaller-1.2.0.tar.bz2
build_autotools ideviceinstaller LIBS=-lz

mkdir -p "$PREFIX/licenses"
for name in openssl libplist libimobiledevice-glue libtatsu libusbmuxd libimobiledevice libzip ideviceinstaller; do
    for license in "$SOURCE_DIR/$name"/COPYING*(N) "$SOURCE_DIR/$name"/LICENSE*(N); do
        cp "$license" "$PREFIX/licenses/$name-${license:t}"
    done
done

for tool in idevice_id ideviceinstaller; do
    [[ -x "$PREFIX/bin/$tool" ]] || { echo "未生成 $tool" >&2; exit 1; }
    minos="$(vtool -show-build "$PREFIX/bin/$tool" | awk '/minos/{print $2}' | sort -Vu)"
    [[ "$minos" == "$DEPLOYMENT_TARGET" ]] || { echo "$tool 最低版本错误: $minos" >&2; exit 1; }
    if otool -L "$PREFIX/bin/$tool" | grep -E '/(opt/homebrew|usr/local)/'; then
        echo "$tool 仍依赖 Homebrew" >&2
        exit 1
    fi
done

echo "macOS 13 $ARCH iOS 工具构建完成: $PREFIX"
