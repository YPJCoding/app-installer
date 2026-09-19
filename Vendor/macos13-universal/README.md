# Bundled command-line tools

These Universal 2 binaries are committed so application builds are reproducible and do not depend on tools installed on the build machine.

## Android Platform Tools

- Tool: `bin/adb`
- Version: Android Debug Bridge 1.0.41, Platform Tools 36.0.2-14143358
- Architectures: `arm64`, `x86_64`
- Source: <https://developer.android.com/tools/releases/platform-tools>
- SHA-256: `534893b946847fdf6f9998108af469e646679824d75098247ca438948fa2dffc`
- Notice: `licenses/Android-SDK-Platform-Tools-NOTICE.txt`

The iOS tools and their licenses are stored in the same `bin` and `licenses` directories. Run `scripts/build-ios-tools-universal.sh` to rebuild the iOS tools.
