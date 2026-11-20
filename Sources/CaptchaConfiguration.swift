import Foundation

/// AJ-Captcha Swift 组件的对外配置。
///
/// 使用方式：
/// ```swift
/// let configuration = CaptchaConfiguration(
///     serverURL: URL(string: "https://example.com/captcha-api")!
/// )
/// ```
/// `serverURL` 只填写服务根地址，组件会自动拼接 `/captcha/get` 与 `/captcha/check`。
public struct CaptchaConfiguration {

    /// AJ-Captcha 服务根地址，例如 `https://example.com/captcha-api`。
    public let serverURL: URL

    /// 滑动条提示覆盖文案；为 nil 时使用 `aj_captcha.slider_prompt` 的国际化配置。
    public let sliderPrompt: String?

    /// 组件固定文案的国际化配置；未配置时读取系统 `Localizable.strings`，仍缺失时回退简体中文。
    public let localization: CaptchaLocalization

    /// 创建组件配置。
    ///
    /// - Parameters:
    ///   - serverURL: AJ-Captcha 服务根地址；组件会在该地址后拼接 `/captcha/get` 与 `/captcha/check`。
    ///   - sliderPrompt: 滑动条提示覆盖文案；优先级高于国际化配置，传 nil 表示使用国际化文案。
    ///   - localization: 组件国际化文案配置；默认先读取宿主 `Localizable.strings`，缺失项回退简体中文。
    public init(
        serverURL: URL,
        sliderPrompt: String? = nil,
        localization: CaptchaLocalization = CaptchaLocalization()
    ) {
        self.serverURL = serverURL
        self.sliderPrompt = sliderPrompt
        self.localization = localization
    }
}
