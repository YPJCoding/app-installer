# App Installer

[English](README.md) | 简体中文

App Installer 是一款用于 macOS 的 Android 与 iOS 应用安装器。连接设备后，可以通过拖放或文件选择的方式，将 APK 安装到 Android 设备，或将 IPA 安装到 iPhone、iPad。

## 功能

- 自动检测已连接的 Android、iPhone 和 iPad
- 支持拖放或选择 APK、IPA 文件
- 根据安装包类型匹配对应平台的设备
- 支持 Android 覆盖安装、版本降级和自动授予权限
- 显示安装进度、命令输出及常见错误的中文说明
- 集成所需的 Android 和 iOS 命令行工具，使用者无需安装 Homebrew 或 Android Studio
- 支持 Apple Silicon、Intel 和 Universal 2 构建

## 系统要求

- macOS 13 或更高版本
- Android 设备需要开启“开发者选项”和“USB 调试”，并允许当前 Mac 进行调试
- iPhone 或 iPad 需要信任当前 Mac；部分安装包还要求设备开启“开发者模式”

IPA 的安装仍受 Apple 签名与设备授权规则限制。安装包必须具有有效签名，并包含目标设备所需的授权信息；App Installer 不会修改或绕过签名。

## 使用方法

1. 将 Android 设备、iPhone 或 iPad 连接到 Mac。
2. 在设备上完成信任或调试授权。
3. 将 APK 或 IPA 拖入窗口，也可以手动选择文件。
4. 选择目标设备并开始安装。

## 从源码构建

项目使用 Swift 和 SwiftUI 开发，并通过 Swift Package Manager 管理依赖。仓库已经包含应用运行所需的预编译命令行工具，普通构建不需要额外安装 Android 或 iOS 工具链。

```bash
make build
```

按架构构建：

```bash
make build-arm64     # Apple Silicon
make build-intel     # Intel
make build-universal # Apple Silicon + Intel
```

构建并启动应用：

```bash
make run
```

验证 Swift Package：

```bash
make test
```

构建结果位于：

```text
build/arm64/App Installer.app
build/intel/App Installer.app
build/universal/App Installer.app
```

## 制作 DMG

```bash
make dmg-arm64
make dmg-intel
make dmg-universal
```

生成的 DMG 和 SHA-256 校验文件位于 `dist/`。

## 重建 iOS 工具

只有在升级或重新生成 `Vendor` 中的 iOS 工具时，才需要安装以下构建依赖：

```bash
brew install automake libtool cmake pkg-config
./scripts/build-ios-tools-universal.sh
```

该脚本会分别为 arm64 和 x86_64 构建最低支持 macOS 13 的工具，再合并为 Universal 2 文件。

## 第三方组件

App Installer 包含以下开源项目提供的工具：

- [Android SDK Platform Tools](https://developer.android.com/tools/releases/platform-tools)
- [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice)
- [ideviceinstaller](https://github.com/libimobiledevice/ideviceinstaller)

构建应用时，相关许可证和声明会复制到 `Contents/Resources/Tools/licenses`。分发修改后的版本前，请确认遵守各组件的许可证及 Android SDK Platform Tools 的相关条款。
