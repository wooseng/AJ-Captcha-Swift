import SwiftUI

/// SwiftUI 弹出验证码接入修饰符。
public extension View {

    /// 给任意视图挂载全屏 AJ-Captcha 弹窗。
    ///
    /// 使用方式：
    /// ```swift
    /// @State private var isCaptchaPresented = false
    ///
    /// Content()
    ///     .captchaPopup(
    ///         isPresented: $isCaptchaPresented,
    ///         configuration: configuration
    ///     ) { result in
    ///         submitLogin(captchaVerification: result.captchaVerification)
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: 是否显示验证码弹窗。
    ///   - configuration: AJ-Captcha 服务地址与展示配置。
    ///   - onSuccess: `/captcha/check` 成功后的回调；组件内部失败或取消时不回调。
    /// - Returns: 挂载弹窗后的视图。
    func captchaPopup(
        isPresented: Binding<Bool>,
        configuration: CaptchaConfiguration,
        onSuccess: @escaping (CaptchaResult) -> Void
    ) -> some View {
        overlay {
            if isPresented.wrappedValue {
                CaptchaPopupView(
                    isPresented: isPresented,
                    configuration: configuration,
                    onSuccess: onSuccess
                )
            }
        }
    }
}
