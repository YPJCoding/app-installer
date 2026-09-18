#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/version.env"
UPDATES_DIR="$ROOT_DIR/dist/updates"
ARCHIVE_PATH="$UPDATES_DIR/App-Installer-$APP_VERSION.zip"
APPCAST_PATH="$UPDATES_DIR/appcast.xml"
REPOSITORY="YPJCoding/app-installer"
RELEASE_TAG="updates"

[[ -f "$ARCHIVE_PATH" && -f "$APPCAST_PATH" ]] || {
    echo "请先运行 make update-archive && ./scripts/generate-appcast.sh。" >&2
    exit 1
}

if ! gh release view "$RELEASE_TAG" --repo "$REPOSITORY" >/dev/null 2>&1; then
    gh release create "$RELEASE_TAG" \
        --repo "$REPOSITORY" \
        --title "App Installer Updates" \
        --notes "Sparkle automatic update feed."
fi

ASSETS=("$ARCHIVE_PATH" "$APPCAST_PATH")
for delta_path in "$UPDATES_DIR"/*.delta(N); do
    ASSETS+=("$delta_path")
done

gh release upload "$RELEASE_TAG" \
    "${ASSETS[@]}" \
    --repo "$REPOSITORY" --clobber

echo "已发布 App Installer $APP_VERSION ($BUILD_NUMBER)"
