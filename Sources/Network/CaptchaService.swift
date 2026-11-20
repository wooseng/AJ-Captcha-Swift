import Foundation

/// 外部自定义 AJ-Captcha 网络请求实现协议。
///
/// 使用方式：实现该协议并在 `CaptchaConfiguration.service` 中传入。外部实现只负责使用自身网络栈
/// 完成 `/captcha/get` 与 `/captcha/check` 两个请求；坐标换算、AES 加密、二次验证参数生成
/// 和最终业务码判断仍由组件内部完成。
public protocol CaptchaService {

    /// 获取验证码数据。
    ///
    /// - Parameters:
    ///   - captchaType: 验证码类型，外部实现需要传给服务端 `captchaType` 字段。
    ///   - clientUid: 客户端唯一标识，需要与后续 check 请求保持一致。
    /// - Returns: 背景图、滑块图、token 与 AES 密钥。
    /// - Throws: 外部网络框架的任意请求错误。
    func getCaptcha(
        captchaType: CaptchaType,
        clientUid: String
    ) async throws -> CaptchaData

    /// 提交校验请求。
    ///
    /// - Parameters:
    ///   - captchaType: 验证码类型，外部实现需要传给服务端 `captchaType` 字段。
    ///   - pointJson: 组件按 AJ-Captcha 协议加密或明文序列化后的滑动坐标。
    ///   - token: `/captcha/get` 返回的验证码令牌。
    ///   - clientUid: 客户端唯一标识，需要与 get 请求保持一致。
    /// - Returns: 服务端业务码与提示信息。
    /// - Throws: 外部网络框架的任意请求错误。
    func check(
        captchaType: CaptchaType,
        pointJson: String,
        token: String,
        clientUid: String
    ) async throws -> CaptchaCheckResponse
}
