import SwiftUI

/// 全屏半透明弹出验证码视图。
///
/// 使用方式：调用方通常不直接使用该视图，而是对页面根视图调用 `captchaPopup` 修饰符。
struct CaptchaPopupView: View {

    /// 控制弹窗是否显示。
    @Binding private var isPresented: Bool

    /// 验证码组件状态机。
    @StateObject private var viewModel: CaptchaViewModel

    /// 最终 `/captcha/check` 成功后的回调。
    private let onSuccess: (CaptchaResult) -> Void

    /// 创建弹窗视图。
    ///
    /// - Parameters:
    ///   - isPresented: 弹窗显示状态绑定；组件关闭、取消或自动收起时会将其置回 false。
    ///   - configuration: 组件配置，包含服务地址与滑动提示。
    ///   - onSuccess: 最终校验成功后的回调；组件内部失败时不回调。
    init(
        isPresented: Binding<Bool>,
        configuration: CaptchaConfiguration,
        onSuccess: @escaping (CaptchaResult) -> Void
    ) {
        self._isPresented = isPresented
        self._viewModel = StateObject(
            wrappedValue: CaptchaViewModel(configuration: configuration)
        )
        self.onSuccess = onSuccess
    }

    /// 弹窗主体。
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        close()
                    }

                captchaContainer
                    .frame(width: min(proxy.size.width - 32, 342))
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .onAppear {
            CaptchaLogger.info("popup appear phase=\(String(describing: viewModel.phase))")
            if viewModel.phase == .idle {
                viewModel.loadCaptcha()
            }
        }
        .onChange(of: viewModel.phase) { phase in
            if case .success = phase {
                Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    close()
                }
            }

            guard case .failure(_, true) = phase else { return }
            Task {
                try? await Task.sleep(nanoseconds: 800_000_000)
                guard viewModel.phase == phase else { return }
                CaptchaLogger.info("auto refresh after check failure")
                viewModel.loadCaptcha()
            }
        }
    }

    /// 居中的白色验证码容器。
    private var captchaContainer: some View {
        VStack(spacing: 0) {
            header

            switch viewModel.phase {
            case .idle, .loading:
                loadingView
                    .padding(16)
            case .ready, .checking, .success, .failure(_, true):
                if let backgroundImage = viewModel.backgroundImage,
                   let jigsawImage = viewModel.jigsawImage {
                    CaptchaSliderView(
                        backgroundImage: backgroundImage,
                        jigsawImage: jigsawImage,
                        phase: viewModel.phase,
                        sliderPrompt: viewModel.sliderPrompt,
                        localization: viewModel.localization,
                        onCheck: { displayedOffset, displayedWidth in
                            viewModel.check(
                                displayedOffset: displayedOffset,
                                displayedImageWidth: displayedWidth,
                                onSuccess: onSuccess
                            )
                        },
                        onRefresh: {
                            viewModel.loadCaptcha()
                        }
                    )
                    .padding(16)
                } else {
                    loadingView
                        .padding(16)
                }
            case .failure(let message, let autoRefreshes):
                failureView(
                    message: message,
                    autoRefreshes: autoRefreshes
                )
                .padding(16)
            }
        }
    }

    /// 顶部标题与关闭按钮。
    private var header: some View {
        HStack {
            Text(viewModel.localizedText(.title))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(viewModel.localizedText(.close))
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(height: 44)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(white: 0.9))
                .frame(height: 1)
        }
    }

    /// 加载状态视图。
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(viewModel.localizedText(.loading))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(width: 310, height: 211)
    }

    /// 请求失败状态视图。
    ///
    /// - Parameters:
    ///   - message: 展示给用户的错误信息。
    ///   - autoRefreshes: 是否由滑动校验失败触发；该场景按 HTML 示例自动刷新。
    private func failureView(
        message: String,
        autoRefreshes: Bool
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if !autoRefreshes {
                Button(viewModel.localizedText(.retry)) {
                    viewModel.loadCaptcha()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
        }
        .frame(width: 310, height: 211)
    }

    /// 关闭弹窗；不会产生成功回调。
    private func close() {
        CaptchaLogger.info("popup close")
        isPresented = false
    }
}
