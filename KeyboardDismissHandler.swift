import UIKit

/// Demo 全局键盘收起处理器。
///
/// 使用方式：在 Demo 根视图 `onAppear` 时调用 `install()`。
/// 处理器向当前 Window 添加 `cancelsTouchesInView = false` 的轻点识别器，
/// 因此不会抢占 SwiftUI Button、TextField 或滑块手势；点击非输入控件区域时收起键盘。
final class KeyboardDismissHandler: NSObject, UIGestureRecognizerDelegate {

    /// 全局共享实例，避免重复向 Window 添加手势识别器。
    static let shared = KeyboardDismissHandler()

    /// 已安装到 Window 的轻点识别器。
    private var tapRecognizer: UITapGestureRecognizer?

    /// 创建处理器；仅允许通过共享实例访问。
    private override init() {
        super.init()
    }

    /// 向当前 Key Window 安装键盘收起轻点识别器。
    func install() {
        guard tapRecognizer == nil else { return }

        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let window = windowScenes.flatMap(\.windows).first(where: \.isKeyWindow) else {
            return
        }

        let recognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTap)
        )
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self
        window.addGestureRecognizer(recognizer)
        tapRecognizer = recognizer
    }

    /// 轻点非输入控件区域时，让当前第一响应者退出键盘。
    @objc private func handleTap() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    /// 过滤文本输入类控件，避免点击输入框后被立即收起键盘。
    /// - Parameters:
    ///   - gestureRecognizer: 当前轻点识别器。
    ///   - touch: 系统传入的触摸事件。
    /// - Returns: 触摸链路上包含输入控件时返回 false，其余区域返回 true。
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        var view = touch.view
        while let currentView = view {
            if currentView is UITextField || currentView is UITextView {
                return false
            }
            view = currentView.superview
        }
        return true
    }
}
