# App Installer

[English](README.md) | 简体中文

App Installer 是一款 macOS 应用，用于将 APK 安装到 Android 设备，或将 IPA 安装到 iPhone 和 iPad。应用内置所需的 Android 与 iOS 命令行工具，普通用户无需安装 Homebrew、Android Studio 或其他开发工具。

## 下载与安装

App Installer 支持 macOS 13 及更高版本，一个 Universal 2 安装包同时支持 Apple Silicon 和 Intel Mac。

- [下载最新版本](https://github.com/YPJCoding/app-installer/releases/latest/download/App-Installer-macOS13.dmg)

打开 DMG，将 App Installer 拖入“应用程序”文件夹。如果 macOS 首次启动时阻止打开，请按住 Control 键点按应用，选择“打开”并确认。应用也可以通过“App Installer > 检查更新…”获取后续版本。

## 功能

- 自动检测已连接的 Android 设备、iPhone 和 iPad
- 支持拖放或选择 APK、IPA 文件
- 根据安装包类型匹配对应平台的设备
- 支持 Android 覆盖安装、版本降级和自动授予权限
- 显示安装进度、命令输出及常见错误的中文说明
- 内置 ADB、libimobiledevice 和 ideviceinstaller
- 提供应用版本、作者和开源仓库信息
- 以 Universal 2 形式原生支持 Apple Silicon 和 Intel Mac

## 设备准备

### Android

开启“开发者选项”和“USB 调试”，连接设备后允许当前 Mac 进行调试。

### iPhone 和 iPad

连接设备后信任当前 Mac。部分安装包还要求设备开启“开发者模式”。IPA 必须具有有效签名并包含目标设备所需的授权信息；App Installer 不会修改或绕过 Apple 的签名机制。

## 使用方法

1. 连接并解锁目标设备。
2. 在设备上完成信任或 USB 调试授权。
3. 将 APK 或 IPA 拖入窗口，也可以点击“选择安装包…”。
4. 选择目标设备并开始安装。

## 从源码构建

### 开发环境

- macOS 13 或更高版本
- Swift 6.1 工具链和 macOS SDK
- Git 和 Command Line Tools（可通过 `xcode-select --install` 安装，无需完整 Xcode）
- 首次构建时需要联网下载 Swift Package Manager 依赖

仓库已经包含打包所需的 Android 与 iOS 命令行工具。正常开发和打包不需要 Homebrew 或 Android Studio。

```bash
# 构建 .app
make build

# 构建并启动应用
make run

# 检查 Swift Package 能否编译
make test
```

生成的应用位于 `build/App Installer.app`。未设置 `APP_IDENTITY` 时，构建脚本使用 ad-hoc 签名；正式发布时应提供 Developer ID 签名身份并按 Apple 的要求完成公证。

## 制作安装包

```bash
make dmg
```

DMG 和对应的 SHA-256 校验文件会写入 `dist/`。

```bash
# 验证应用结构、Universal 2 架构和代码签名
make verify
```

## 维护内置工具

日常构建直接使用 `Vendor/macos13-universal` 中已经提交的工具，避免构建结果取决于开发机环境。

### 更新 ADB

从 [Android SDK Platform Tools](https://developer.android.com/tools/releases/platform-tools) 下载 macOS 版本，解压后运行：

```bash
./scripts/update-adb-vendor.sh /path/to/platform-tools
```

脚本会验证 ADB 是否为 Universal 2，并复制 ADB 与官方 NOTICE。更新后还应同步修改 `Vendor/macos13-universal/README.md` 中记录的版本和 SHA-256。

### 重建 iOS 工具

只有升级或重新生成 iOS 工具时才需要 Homebrew 构建依赖：

```bash
brew install automake libtool cmake pkg-config
./scripts/build-ios-tools-universal.sh
```

脚本会生成最低支持 macOS 13 的 Universal 2 iOS 工具，并保留同一 Vendor 目录中的 ADB 与 Android NOTICE。

## 第三方组件与许可

应用包含以下第三方工具：

- [Android SDK Platform Tools](https://developer.android.com/tools/releases/platform-tools)
- [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice)
- [ideviceinstaller](https://github.com/libimobiledevice/ideviceinstaller)

构建时，相关许可证和声明会复制到应用的 `Contents/Resources/Tools/licenses`。分发修改后的版本前，请审阅其中的许可文件以及 Android SDK Platform Tools 的适用条款。
