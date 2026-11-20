import Foundation

    /// 验证码展示阶段。
enum CaptchaPhase: Equatable {

    /// 组件初始状态，尚未发起加载请求。
    case idle

    /// 正在加载或刷新验证码。
    case loading

    /// 验证码可滑动。
    case ready

    /// 正在提交 `/captcha/check`。
    case checking

    /// `/captcha/check` 成功。
    case success

    /// `/captcha/check` 或请求失败；`autoRefreshes` 表示是否按 HTML 示例自动刷新。
    case failure(String, autoRefreshes: Bool)
}
