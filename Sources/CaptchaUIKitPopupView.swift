import SwiftUI

/// UIKit 调用时承载 SwiftUI 验证码弹窗的包装视图。
///
/// 使用方式：由 `UIViewController.presentCaptchaPopup` 内部创建，调用方不直接使用该视图。
/// 当 SwiftUI 弹窗把 `isPresented` 置回 false 时，本视图会通知外部 dismiss 承载用的 UIHostingController。
struct CaptchaUIKitPopupView: View {

    /// SwiftUI 弹窗显示状态；初始进入即展示，关闭或校验成功后变为 false。
    @State private var isPresented = true

    /// AJ-Captcha 服务与展示配置。
    private let configuration: CaptchaConfiguration

    /// `/captcha/check` 成功后的回调。
    private let onSuccess: (CaptchaResult) -> Void

    /// 弹窗需要关闭时通知 UIKit 侧 dismissal 的回调。
    private let onDismiss: () -> Void

    /// 创建 UIKit 弹窗包装视图。
    ///
    /// - Parameters:
    ///   - configuration: AJ-Captcha 服务地址与展示配置。
    ///   - onSuccess: `/captcha/check` 成功后的回调；组件内部失败时不回调。
    ///   - onDismiss: SwiftUI 弹窗关闭后需要 dismiss UIHostingController 的回调。
    init(
        configuration: CaptchaConfiguration,
        onSuccess: @escaping (CaptchaResult) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.configuration = configuration
        self.onSuccess = onSuccess
        self.onDismiss = onDismiss
    }

    /// 包装视图主体。
    var body: some View {
        ZStack {
            if isPresented {
                CaptchaPopupView(
                    isPresented: $isPresented,
                    configuration: configuration,
                    onSuccess: onSuccess
                )
            }
        }
        .onChange(of: isPresented) { presented in
            if !presented {
                onDismiss()
            }
        }
    }
}
