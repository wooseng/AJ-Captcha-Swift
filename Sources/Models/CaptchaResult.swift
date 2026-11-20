import Foundation

/// 组件最终校验成功后回调给调用方的结果。
///
/// `captchaVerification` 是后端 `/auth/login` 等业务接口需要的二次验证参数；
/// `token` 为本次验证码获取时服务端返回的令牌，便于调用方排查日志。
public struct CaptchaResult: Equatable {

    /// `/captcha/check` 成功后生成的二次验证参数，需要原样传给业务服务端。
    public let captchaVerification: String

    /// 本次验证码的服务端令牌。
    public let token: String

    /// 创建回调结果。
    ///
    /// - Parameters:
    ///   - captchaVerification: 可直接回传业务服务端的二次验证参数。
    ///   - token: 本次验证码令牌。
    public init(captchaVerification: String, token: String) {
        self.captchaVerification = captchaVerification
        self.token = token
    }
}
