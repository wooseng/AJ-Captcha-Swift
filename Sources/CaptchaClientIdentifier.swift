import Foundation

/// 持久化的客户端组件标识，行为对应 HTML 示例中 localStorage 的 `slider` 值。
final class CaptchaClientIdentifier {

    /// 全局共享实例，保证 get 与 check 请求使用同一个 clientUid。
    static let shared = CaptchaClientIdentifier()

    /// UserDefaults 存储键。
    private static let storageKey = "com.ajcaptcha.swift.client-uid.slider"

    /// 当前客户端标识。
    let value: String

    /// 创建或读取客户端标识。
    private init() {
        let storage = UserDefaults.standard
        if let saved = storage.string(forKey: Self.storageKey), !saved.isEmpty {
            value = saved
        } else {
            let newValue = UUID().uuidString
            storage.set(newValue, forKey: Self.storageKey)
            value = newValue
        }
    }
}
