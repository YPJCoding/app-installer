# App Installer

面向测试团队的轻量 macOS 安装工具。连接 Android 或 iPhone，拖入 APK / IPA，即可完成安装并看到中文错误提示。

## 当前功能

- 自动发现 Android（ADB）和 iOS（libimobiledevice）设备
- 拖放或选择 APK / IPA
- Android 覆盖安装、允许降级、自动授予权限
- 安装日志与常见错误中文化
- 安装包/设备平台匹配检查

## 构建环境依赖

```bash
brew install android-platform-tools
```

为保证完整功能支持 macOS 13，首次构建先执行：

```bash
brew install automake libtool cmake pkg-config
./scripts/build-ios-tools-universal.sh
```

该脚本会从固定版本源码分别构建 arm64 与 x86_64 静态链接工具，再合成
Universal 2 文件，并验证两个架构的最低系统版本都是 13.0。常规
`make build` 同样生成 Universal 2 主程序，并拒绝嵌入部署目标高于 13.0
的 iOS 工具。

这些构建工具和依赖只需安装在构建机上。`make build` 会把 `adb`、`idevice_id`、
`ideviceinstaller` 及其非系统动态库复制到 App 的
`Contents/Resources/Tools`，并将动态库路径改写为包内相对路径。
最终用户无需安装 Homebrew 或 Android Studio。

iOS 仍遵循 Apple 签名规则：设备需信任 Mac、启用开发者模式，且 Ad Hoc 包必须包含设备 UDID。

## 构建与运行

```bash
make test
make run
```

分别构建不同架构：

```bash
make build-arm64     # Apple Silicon / M 系列
make build-intel     # Intel Mac
make build-universal # 同时支持两种架构
```

制作可拖入“应用程序”安装的 DMG：

```bash
make dmg-arm64
make dmg-intel
make dmg-universal
```

DMG 及其 SHA-256 校验文件输出到 `dist/`。

产物分别位于 `build/arm64/App Installer.app`、
`build/intel/App Installer.app` 和 `build/universal/App Installer.app`。
程序优先使用包内工具；直接通过
`swift run` 开发时，则回退到 Homebrew、Android SDK 或系统路径。

## 第三方许可

构建脚本会将 Android Platform Tools 的 `NOTICE.txt`，以及 iOS 工具和
所有随包动态库的许可证文本放进
`Contents/Resources/Tools/licenses`。对外分发前仍应由发布方审核完整的
第三方依赖清单与 Android SDK 条款；尤其注意 ideviceinstaller 本身采用 GPL。
