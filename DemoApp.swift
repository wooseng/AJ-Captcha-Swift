import AJCaptcha
import SwiftUI

/// Demo 固定配置。
private enum DemoConfiguration {

    /// Demo 默认使用的本地 AJ-Captcha 服务根地址。
    static let serverURL = URL(string: "http://localhost:8080")!
}

/// AJ-Captcha Swift 根目录 Demo。
///
/// Demo 通过 Xcode Local Package 配置引入 `AJCaptcha` 组件；
/// 用 Xcode 打开 `AJCaptchaDemo.xcodeproj` 后选择真机或通用 iOS 设备运行即可。
@main
struct AJCaptchaDemoApp: App {

    /// 验证码弹窗显示状态。
    @State private var isCaptchaPresented = false

    /// 可编辑的 AJ-Captcha 服务根地址。
    @State private var serverURLText = DemoConfiguration.serverURL.absoluteString

    /// 可编辑的滑动提示文案。
    @State private var sliderPrompt = ""

    /// 最近一次成功回调的二次验证参数。
    @State private var captchaVerification = ""

    /// Demo 页面窗口。
    var body: some Scene {
        WindowGroup {
            ContentView(
                isCaptchaPresented: $isCaptchaPresented,
                serverURLText: $serverURLText,
                sliderPrompt: $sliderPrompt,
                captchaVerification: $captchaVerification
            )
        }
    }
}

/// Demo 主页面。
private struct ContentView: View {

    /// 验证码弹窗显示状态。
    @Binding private var isCaptchaPresented: Bool

    /// 可编辑的 AJ-Captcha 服务根地址。
    @Binding private var serverURLText: String

    /// 可编辑的滑动提示文案。
    @Binding private var sliderPrompt: String

    /// 最近一次成功回调的二次验证参数。
    @Binding private var captchaVerification: String

    /// 创建 Demo 主页面。
    ///
    /// - Parameters:
    ///   - isCaptchaPresented: 弹窗显示状态。
    ///   - serverURLText: 服务根地址输入内容。
    ///   - sliderPrompt: 滑动提示输入内容。
    ///   - captchaVerification: 成功后展示的二次验证参数。
    init(
        isCaptchaPresented: Binding<Bool>,
        serverURLText: Binding<String>,
        sliderPrompt: Binding<String>,
        captchaVerification: Binding<String>
    ) {
        self._isCaptchaPresented = isCaptchaPresented
        self._serverURLText = serverURLText
        self._sliderPrompt = sliderPrompt
        self._captchaVerification = captchaVerification
    }

    /// Demo 页面主体。
    var body: some View {
        NavigationView {
            Form {
                Section("服务配置") {
                    TextField("服务地址", text: $serverURLText)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    TextField("滑动提示", text: $sliderPrompt)
                }

                Section {
                    Button("开始验证") {
                        guard URL(string: serverURLText.trimmingCharacters(in: .whitespacesAndNewlines)) != nil else {
                            captchaVerification = "服务地址无效"
                            return
                        }
                        captchaVerification = ""
                        isCaptchaPresented = true
                    }
                } footer: {
                    Text("组件配置在弹窗创建时读取；修改上方内容后需要重新点击“开始验证”。")
                }

                if !captchaVerification.isEmpty {
                    Section("二次验证参数") {
                        Text(captchaVerification)
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("AJ-Captcha")
            .onAppear {
                KeyboardDismissHandler.shared.install()
            }
        }
        .captchaPopup(
            isPresented: $isCaptchaPresented,
            configuration: currentConfiguration ?? CaptchaConfiguration(serverURL: DemoConfiguration.serverURL)
        ) { result in
            captchaVerification = result.captchaVerification
        }
    }

    /// 根据当前输入生成的组件配置。
    private var currentConfiguration: CaptchaConfiguration? {
        guard let serverURL = URL(string: serverURLText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        let prompt = sliderPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return CaptchaConfiguration(
            serverURL: serverURL,
            sliderPrompt: prompt.isEmpty ? nil : prompt
        )
    }
}
