# App Installer

English | [简体中文](README.zh-CN.md)

App Installer is a macOS application for installing APK files on Android devices and IPA files on iPhone and iPad. It bundles the required Android and iOS command-line tools, so users do not need Homebrew, Android Studio, or other development tools.

## Download and Install

App Installer requires macOS 13 or later. One Universal 2 package supports both Apple Silicon and Intel Macs.

- [Download the latest release](https://github.com/YPJCoding/app-installer/releases/latest/download/App-Installer-macOS13.dmg)

Open the DMG and drag App Installer into the Applications folder. If macOS blocks the first launch, Control-click the application, choose **Open**, and confirm. Future versions are also available through **App Installer > Check for Updates…**.

## Features

- Automatically detects connected Android devices, iPhones, and iPads
- Installs APK and IPA files by drag and drop or file selection
- Matches each package with devices on the corresponding platform
- Supports Android replacement installs, version downgrades, and automatic permission grants
- Shows installation progress, command output, and readable descriptions for common errors
- Bundles ADB, libimobiledevice, and ideviceinstaller
- Shows application version, author, and open-source repository information
- Runs natively on Apple Silicon and Intel Macs as a Universal 2 application

## Prepare a Device

### Android

Enable Developer options and USB debugging. After connecting the device, authorize the Mac for debugging.

### iPhone and iPad

Trust the Mac after connecting the device. Some packages also require Developer Mode. An IPA must have a valid signature and include the authorization required for the target device; App Installer does not modify or bypass Apple's code-signing system.

## Usage

1. Connect and unlock the target device.
2. Complete the trust or USB debugging authorization prompt on the device.
3. Drag an APK or IPA into the window, or click **Choose Package…**.
4. Select the target device and start the installation.

## Build from Source

### Development Requirements

- macOS 13 or later
- Swift 6.1 toolchain and macOS SDK
- Git and Command Line Tools (install with `xcode-select --install`; the full Xcode application is not required)
- An internet connection for the initial Swift Package Manager dependency download

The Android and iOS command-line tools used for packaging are committed under `Vendor`. Normal development and packaging do not require Homebrew or Android Studio.

```bash
# Build the .app bundle
make build

# Build and launch the application
make run

# Check that the Swift package compiles
make test
```

The generated application is written to `build/App Installer.app`. Without `APP_IDENTITY`, the build script uses an ad-hoc signature. Production releases should provide a Developer ID signing identity and follow Apple's notarization requirements.

## Create an Installer

```bash
make dmg
```

The DMG and its SHA-256 checksum are written to `dist/`.

```bash
# Verify the app structure, Universal 2 architecture, and code signature
make verify
```

## Maintain Bundled Tools

Normal builds use the committed tools in `Vendor/macos13-universal`, keeping build output independent of tools installed on the build machine.

### Update ADB

Download Android SDK Platform Tools for macOS from the [official release page](https://developer.android.com/tools/releases/platform-tools), extract it, and run:

```bash
./scripts/update-adb-vendor.sh /path/to/platform-tools
```

The script verifies that ADB is Universal 2 and copies both ADB and the official NOTICE. After updating, also update the version and SHA-256 recorded in `Vendor/macos13-universal/README.md`.

### Rebuild the iOS Tools

Homebrew build dependencies are required only when upgrading or regenerating the iOS tools:

```bash
brew install automake libtool cmake pkg-config
./scripts/build-ios-tools-universal.sh
```

The script creates Universal 2 iOS tools targeting macOS 13 and preserves ADB and the Android NOTICE in the shared Vendor directory.

## Third-Party Components and Licenses

The application includes these third-party tools:

- [Android SDK Platform Tools](https://developer.android.com/tools/releases/platform-tools)
- [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice)
- [ideviceinstaller](https://github.com/libimobiledevice/ideviceinstaller)

During packaging, the corresponding licenses and notices are copied to `Contents/Resources/Tools/licenses`. Before distributing a modified build, review those files and the applicable Android SDK Platform Tools terms.
