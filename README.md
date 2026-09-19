# App Installer

English | [简体中文](README.zh-CN.md)

App Installer is a macOS application for installing Android and iOS apps. Connect a device, then drag and drop or select an APK for Android, or an IPA for iPhone and iPad.

## Download

App Installer requires macOS 13 or later. One Universal 2 package supports both Apple Silicon and Intel Macs:

- [Download App Installer](https://github.com/YPJCoding/app-installer/releases/latest/download/App-Installer-macOS13.dmg)

Open the DMG and drag App Installer into the Applications folder. If macOS blocks the first launch, Control-click the application, choose **Open**, and confirm once. Future versions can be installed from **App Installer > Check for Updates**.

## Features

- Automatically detects connected Android devices, iPhones, and iPads
- Installs APK and IPA files by drag and drop or file selection
- Matches each package with devices on the corresponding platform
- Supports Android replacement installs, version downgrades, and automatic permission grants
- Shows installation progress, command output, and readable descriptions for common errors
- Bundles the required Android and iOS command-line tools, with no Homebrew or Android Studio installation required for users
- Runs natively on Apple Silicon and Intel Macs as a Universal 2 application

## Requirements

- macOS 13 or later
- Android devices must have Developer options and USB debugging enabled, and must authorize the Mac
- iPhone and iPad must trust the Mac; some packages also require Developer Mode to be enabled

IPA installation remains subject to Apple's code-signing and device authorization rules. The package must have a valid signature and include the required authorization for the target device. App Installer does not modify or bypass code signing.

## Usage

1. Connect an Android device, iPhone, or iPad to the Mac.
2. Complete the trust or USB debugging authorization prompt on the device.
3. Drag an APK or IPA into the window, or select a file manually.
4. Select the target device and start the installation.

## Build from Source

App Installer is built with Swift and SwiftUI and uses Swift Package Manager for dependencies. The Android and iOS command-line tools required to build the app are included in the repository, so Android Platform Tools, Homebrew, and Android Studio are not required.

```bash
make build
```

Build and launch the application:

```bash
make run
```

Validate the Swift package:

```bash
make test
```

Build output is written to:

```text
build/App Installer.app
```

## Create a DMG

```bash
make dmg
```

Generated DMG files and their SHA-256 checksums are written to `dist/`.

## Rebuild the iOS Tools

The following build dependencies are only needed when upgrading or regenerating the iOS tools stored in `Vendor`:

```bash
brew install automake libtool cmake pkg-config
./scripts/build-ios-tools-universal.sh
```

The script creates Universal 2 iOS tools with macOS 13 as the minimum deployment target.

## Third-Party Components

App Installer includes tools from these open-source projects:

- [Android SDK Platform Tools](https://developer.android.com/tools/releases/platform-tools)
- [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice)
- [ideviceinstaller](https://github.com/libimobiledevice/ideviceinstaller)

Licenses and notices are copied into `Contents/Resources/Tools/licenses` when the application is built. Before distributing a modified version, review the licenses of the included components and the applicable Android SDK Platform Tools terms.
