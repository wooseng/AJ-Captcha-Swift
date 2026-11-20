import SwiftUI
import UIKit

/// UIKit 页面接入 AJ-Captcha 的便利方法。
public extension UIViewController {

    /// 以全屏半透明弹窗形式展示 AJ-Captcha 验证码。
    ///
    /// 使用方式：
    /// ```swift
    /// presentCaptchaPopup(configuration: configuration) { result in
    ///     login(captchaVerification: result.captchaVerification)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - configuration: AJ-Captcha 服务地址与展示配置。
    ///   - onSuccess: `/captcha/check` 成功后的回调；组件内部失败或取消时不回调。
    func presentCaptchaPopup(
        configuration: CaptchaConfiguration,
        onSuccess: @escaping (CaptchaResult) -> Void
    ) {
        let hostingController = UIHostingController(
            rootView: CaptchaUIKitPopupView(
                configuration: configuration,
                onSuccess: onSuccess,
                onDismiss: { [weak self] in
                    self?.dismiss(animated: false)
                }
            )
        )
        hostingController.view.backgroundColor = .clear
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve

        present(
            hostingController,
            animated: false
        )
    }
}
