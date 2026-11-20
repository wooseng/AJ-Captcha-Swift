import Foundation

/// `/captcha/get` 请求参数。
struct CaptchaGetRequest: Encodable {

    /// 验证码类型；当前 Swift 组件实现 HTML 示例中的滑动拼图。
    let captchaType: CaptchaType

    /// 客户端组件唯一标识，与 HTML 示例的 `clientUid` 一致。
    let clientUid: String

    /// 客户端请求时间戳，单位毫秒。
    let ts: Int64
}
