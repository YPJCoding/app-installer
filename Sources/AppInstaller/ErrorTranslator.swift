import Foundation

struct ErrorTranslator {
    static func message(for raw: String) -> String {
        let text = raw.lowercased()
        if text.contains("unauthorized") {
            return "手机尚未授权此 Mac。请解锁 Android 手机，并在 USB 调试提示中点按“允许”。"
        }
        if text.contains("no devices") || text.contains("device not found") || text.contains("no device") {
            return "未找到设备。请检查数据线、解锁手机，并确认 USB 调试或信任关系已开启。"
        }
        if text.contains("version_downgrade") {
            return "手机中的 App 版本高于当前安装包。可勾选“允许降级安装”后重试。"
        }
        if text.contains("insufficient_storage") {
            return "设备存储空间不足，请清理空间后重试。"
        }
        if text.contains("applicationverificationfailed") || text.contains("verification failed") {
            return "IPA 无法通过验证。请确认签名有效、设备 UDID 在描述文件中，并已开启开发者模式。"
        }
        if text.contains("ideviceinstaller") || text.contains("idevice_id") {
            return "未安装 iOS 设备工具。请运行：brew install libimobiledevice ideviceinstaller"
        }
        if text.contains("adb") && text.contains("未找到") {
            return "未安装 Android Platform Tools，或 adb 不在常用路径中。"
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "安装失败，设备没有返回详细原因。" : trimmed
    }
}
