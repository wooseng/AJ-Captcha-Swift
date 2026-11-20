import Foundation

/// AJ-Captcha 组件的国际化文案配置。
///
/// 文案读取优先级：
/// 1. `CaptchaLocalization` 中传入的 `overrides`
/// 2. 指定 bundle 的 `Localizable.strings`
/// 3. 组件内置简体中文
///
/// 使用方式：
/// ```swift
/// let localization = CaptchaLocalization(overrides: [
///     .title: "Security verification",
///     .sliderPrompt: "Slide right to verify"
/// ])
/// ```
/// 所有 key 都以 `aj_captcha.` 开头；未配置的 key 自动读取宿主 App 的
/// `Localizable.strings`，系统配置也缺失时回退到内置简体中文文案。
public struct CaptchaLocalization {
    /// 调用方传入的文案覆盖表；只覆盖需要变更的语言，缺失项继续读取系统配置。
    private let overrides: [CaptchaLocalizationKey: String]

    /// 查询 `Localizable.strings` 的 bundle；默认读取宿主 App 配置。
    private let bundle: Bundle

    /// 创建国际化配置。
    ///
    /// - Parameters:
    ///   - overrides: 以组件 key 为下标的文案覆盖表；非空字符串优先级最高。
    ///   - bundle: `Localizable.strings` 所在 bundle；默认为宿主 App 的 `Bundle.main`。
    public init(
        overrides: [CaptchaLocalizationKey: String] = [:],
        bundle: Bundle = .main
    ) {
        self.overrides = overrides
        self.bundle = bundle
    }

    /// 读取指定 key 的文案。
    ///
    /// - Parameter key: 组件国际化 key。
    /// - Returns: 依次返回 `CaptchaLocalization` 覆盖文案、系统 `Localizable.strings`
    ///   文案；两者都没有配置时返回内置简体中文文案。
    public subscript(key: CaptchaLocalizationKey) -> String {
        if let override = overrides[key], !override.isEmpty {
            return override
        }

        let systemText = bundle.localizedString(forKey: key.rawValue, value: nil, table: nil)
        if !systemText.isEmpty, systemText != key.rawValue {
            return systemText
        }

        return Self.simplifiedChineseText(for: key)
    }

    /// 读取格式化文案。
    ///
    /// - Parameters:
    ///   - key: 组件国际化 key。
    ///   - arguments: `String(format:)` 需要的格式化参数。
    /// - Returns: 格式化后的文案；未配置时使用简体中文模板格式化。
    public func formatted(
        _ key: CaptchaLocalizationKey,
        _ arguments: CVarArg...
    ) -> String {
        String(format: self[key], arguments: arguments)
    }

    /// 查询某个 key 的内置简体中文文案。
    ///
    /// - Parameter key: 组件国际化 key。
    /// - Returns: 简体中文默认文案。
    public static func simplifiedChineseText(
        for key: CaptchaLocalizationKey
    ) -> String {
        switch key {
        case .title:
            return "请完成安全验证"
        case .sliderPrompt:
            return "向右滑动完成验证"
        case .loading:
            return "验证码加载中..."
        case .retry:
            return "重新加载"
        case .success:
            return "验证成功"
        case .failure:
            return "验证失败"
        case .close:
            return "关闭验证码"
        case .refresh:
            return "刷新验证码"
        case .imageError:
            return "验证码图片解析失败"
        case .aesError:
            return "验证码加密失败"
        case .invalidServerError:
            return "验证码服务地址无效"
        case .invalidResponseError:
            return "验证码服务响应异常"
        case .httpError:
            return "验证码服务请求失败（HTTP %d）"
        case .unknownServerError:
            return "验证码服务返回未知错误（%@）"
        case .transportError:
            return "验证码网络请求失败（%@）"
        }
    }
}
