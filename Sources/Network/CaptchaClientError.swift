import Foundation

/// 组件内部网络与协议错误。
///
/// UI 层通过 `message(in:)` 将错误转换为国际化文案；`LocalizedError` 保持简体中文回退，
/// 便于调用方未接入组件弹窗时仍能得到可读信息。
enum CaptchaClientError: Error {

    /// 服务地址无法拼接成合法 URL。
    case invalidServerURL

    /// 服务端响应不是合法的 AJ-Captcha JSON 结构。
    case invalidResponse

    /// HTTP 状态码不在 2xx 范围内。
    case httpError(statusCode: Int)

    /// 服务端返回业务失败信息；内容由服务端动态下发。
    case serverMessage(String)

    /// 系统网络请求失败；关联值为系统错误描述。
    case transport(String)

    /// AES 加密失败；关联值为 CommonCrypto 状态码。
    case aes(status: Int)

    /// 使用指定国际化配置生成 UI 展示文案。
    ///
    /// - Parameter localization: 组件国际化配置。
    /// - Returns: 已按配置语言格式化的错误描述。
    func message(
        in localization: CaptchaLocalization
    ) -> String {
        switch self {
        case .invalidServerURL:
            return localization[.invalidServerError]
        case .invalidResponse:
            return localization[.invalidResponseError]
        case .httpError(let statusCode):
            return localization.formatted(.httpError, statusCode)
        case .serverMessage(let message):
            return message
        case .transport(let message):
            return localization.formatted(.transportError, message)
        case .aes:
            return localization[.aesError]
        }
    }
}

/// 为直接使用错误的调用方提供简体中文回退描述。
extension CaptchaClientError: LocalizedError {

    /// 简体中文错误描述。
    var errorDescription: String? {
        message(in: CaptchaLocalization())
    }
}
