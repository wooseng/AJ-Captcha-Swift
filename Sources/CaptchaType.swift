import Foundation

/// AJ-Captcha 服务端支持的验证码类型。
///
/// 使用方式：通过 `CaptchaConfiguration.captchaType` 传入；当前 Swift 组件实现滑动拼图。
public enum CaptchaType: String, Codable {

    /// AJ-Captcha HTML 示例中的滑动拼图验证码。
    case blockPuzzle = "blockPuzzle"
}
