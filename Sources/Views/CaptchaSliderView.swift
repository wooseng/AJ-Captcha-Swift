import SwiftUI

/// 验证码图片与滑动条视图。
///
/// 使用方式：由 `CaptchaPopupView` 内部创建，负责拖动交互与结果反馈。
struct CaptchaSliderView: View {

    /// 背景图。
    private let backgroundImage: UIImage

    /// 滑块拼图。
    private let jigsawImage: UIImage

    /// 当前验证阶段。
    private let phase: CaptchaPhase

    /// 滑动条提示文案。
    private let sliderPrompt: String

    /// 组件国际化配置。
    private let localization: CaptchaLocalization

    /// 误触阈值比例；松手位移低于最大可滑动距离乘以该值时直接回弹。
    private let accidentalTouchThreshold: Double

    /// 提交滑动校验的回调。
    private let onCheck: (
        _ displayedOffset: Double,
        _ displayedSliderMaxOffset: Double,
        _ displayedImageWidth: Double
    ) -> Void

    /// 刷新验证码的回调。
    private let onRefresh: () -> Void

    /// 当前滑块偏移。
    @State private var offset: CGFloat = 0

    /// 手势开始时的滑块偏移。
    @State private var dragStartOffset: CGFloat = 0

    /// 创建滑动视图。
    ///
    /// - Parameters:
    ///   - backgroundImage: `/captcha/get` 返回的背景图。
    ///   - jigsawImage: `/captcha/get` 返回的滑块拼图。
    ///   - phase: 当前验证阶段。
    ///   - sliderPrompt: 滑动条提示文案。
    ///   - localization: 组件国际化配置。
    ///   - accidentalTouchThreshold: 误触阈值比例，范围 0...1。
    ///   - onCheck: 松手后的提交回调，参数依次为滑块屏幕偏移、滑块最大屏幕偏移与背景图显示宽度。
    ///   - onRefresh: 点击刷新后的回调。
    init(
        backgroundImage: UIImage,
        jigsawImage: UIImage,
        phase: CaptchaPhase,
        sliderPrompt: String,
        localization: CaptchaLocalization,
        accidentalTouchThreshold: Double,
        onCheck: @escaping (
            _ displayedOffset: Double,
            _ displayedSliderMaxOffset: Double,
            _ displayedImageWidth: Double
        ) -> Void,
        onRefresh: @escaping () -> Void
    ) {
        self.backgroundImage = backgroundImage
        self.jigsawImage = jigsawImage
        self.phase = phase
        self.sliderPrompt = sliderPrompt
        self.localization = localization
        self.accidentalTouchThreshold = accidentalTouchThreshold
        self.onCheck = onCheck
        self.onRefresh = onRefresh
    }

    /// 滑动视图主体。
    var body: some View {
        GeometryReader { proxy in
            let imageWidth = min(proxy.size.width, 310)
            let imageHeight = backgroundImage.size.height > 0
                ? imageWidth * backgroundImage.size.height / backgroundImage.size.width
                : imageWidth * 155 / 310
            let sliderHeight: CGFloat = 40
            let thumbSize: CGFloat = 40
            let sliderMaxOffset = imageWidth - thumbSize

            VStack(alignment: .center, spacing: 15) {
                imageView(
                    imageWidth: imageWidth,
                    imageHeight: imageHeight,
                    sliderMaxOffset: sliderMaxOffset
                )

                sliderView(
                    imageWidth: imageWidth,
                    sliderHeight: sliderHeight,
                    thumbSize: thumbSize,
                    sliderMaxOffset: sliderMaxOffset
                )
            }
            .frame(width: proxy.size.width, height: imageHeight + 15 + sliderHeight)
            .onChange(of: phase) { newPhase in
                if newPhase == .loading {
                    offset = 0
                    dragStartOffset = 0
                }
            }
        }
        .frame(height: 211)
    }

    /// 生成背景图、拼图、刷新按钮与结果提示。
    ///
    /// - Parameters:
    ///   - imageWidth: 背景图显示宽度。
    ///   - imageHeight: 背景图显示高度。
    ///   - sliderMaxOffset: 滑块在轨道上的最大显示偏移。
    private func imageView(
        imageWidth: CGFloat,
        imageHeight: CGFloat,
        sliderMaxOffset: CGFloat
    ) -> some View {
        let jigsawMaxOffset = imageWidth - jigsawDisplayWidth(
            imageWidth: imageWidth,
            imageHeight: imageHeight
        )

        return ZStack(alignment: .topLeading) {
            Image(uiImage: backgroundImage)
                .resizable()
                .frame(width: imageWidth, height: imageHeight)

            Image(uiImage: jigsawImage)
                .resizable()
                .frame(
                    width: jigsawDisplayWidth(imageWidth: imageWidth, imageHeight: imageHeight),
                    height: imageHeight
                )
                // Android 版本先换算为滑块比例，再按拼图最大位移移动拼图。
                .offset(
                    x: jigsawOffset(
                        displayedOffset: offset,
                        sliderMaxOffset: sliderMaxOffset,
                        jigsawMaxOffset: jigsawMaxOffset
                    )
                )

            VStack {
                HStack {
                    Spacer()
                    Button {
                        onRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.black.opacity(0.35))
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(localization[.refresh])
                }
                Spacer()
                if case .failure = phase {
                    Text(localization[.failure])
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.75))
                } else if phase == .success {
                    Text(localization[.success])
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.75))
                }
            }
            .frame(width: imageWidth, height: imageHeight)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color(white: 0.87), lineWidth: 1)
        )
    }

    /// 生成滑动条。
    ///
    /// - Parameters:
    ///   - imageWidth: 滑动条宽度，与背景图一致。
    ///   - sliderHeight: 滑动条高度。
    ///   - thumbSize: 可拖动按钮尺寸。
    ///   - sliderMaxOffset: 滑块最大可滑动偏移。
    private func sliderView(
        imageWidth: CGFloat,
        sliderHeight: CGFloat,
        thumbSize: CGFloat,
        sliderMaxOffset: CGFloat
    ) -> some View {
        let isEnabled = phase == .ready
        let thumbColor = phase == .success
            ? Color(red: 0.31, green: 0.68, blue: 0.31)
            : (isFailure ? Color.red : Color(red: 0.2, green: 0.48, blue: 0.72))

        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .stroke(isEnabled ? Color(white: 0.87) : thumbColor, lineWidth: 1)
                .background(Color.white.cornerRadius(4))

            Rectangle()
                .fill(thumbColor.opacity(phase == .success ? 0.12 : 0.08))
                .frame(width: max(offset + thumbSize / 2, 0))
                .padding(1)

            if offset == 0 {
                Text(sliderPrompt)
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.35))
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .frame(width: imageWidth, alignment: .center)
                    .allowsHitTesting(false)
            }

            thumbView(
                size: thumbSize,
                color: thumbColor,
                isEnabled: isEnabled
            )
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isEnabled else { return }
                        let next = dragStartOffset + value.translation.width
                        offset = min(max(0, next), sliderMaxOffset)
                    }
                    .onEnded { _ in
                        guard isEnabled else { return }

                        let thresholdOffset = sliderMaxOffset * CGFloat(accidentalTouchThreshold)
                        if offset < thresholdOffset {
                            CaptchaLogger.info(
                                "check ignored by accidental threshold offset=\(offset) threshold=\(thresholdOffset)"
                            )
                            withAnimation(.easeOut(duration: 0.2)) {
                                offset = 0
                            }
                            return
                        }

                        onCheck(offset, sliderMaxOffset, imageWidth)
                    }
            )
        }
        .frame(width: imageWidth, height: sliderHeight)
    }

    /// 生成滑块按钮。
    ///
    /// - Parameters:
    ///   - size: 按钮尺寸。
    ///   - color: 状态颜色。
    ///   - isEnabled: 是否允许拖动。
    private func thumbView(
        size: CGFloat,
        color: Color,
        isEnabled: Bool
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

            Image(systemName: symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }

    /// 当前阶段是否为失败状态。
    private var isFailure: Bool {
        if case .failure = phase { return true }
        return false
    }

    /// 根据验证阶段返回滑块图标。
    private var symbolName: String {
        switch phase {
        case .success:
            return "checkmark"
        case .failure:
            return "xmark"
        default:
            return "chevron.right.2"
        }
    }

    /// 计算 HTML 示例布局中的拼图显示宽度。
    ///
    /// - Parameters:
    ///   - imageWidth: 背景图显示宽度。
    ///   - imageHeight: 背景图显示高度。
    /// - Returns: 等比缩放后的拼图宽度。
    private func jigsawDisplayWidth(
        imageWidth: CGFloat,
        imageHeight: CGFloat
    ) -> CGFloat {
        guard jigsawImage.size.height > 0 else { return imageWidth * 47 / 310 }
        return jigsawImage.size.width * imageHeight / jigsawImage.size.height
    }

    /// 将滑块显示偏移换算成拼图显示偏移。
    ///
    /// - Parameters:
    ///   - displayedOffset: 滑块当前显示偏移。
    ///   - sliderMaxOffset: 滑块最大显示偏移。
    ///   - jigsawMaxOffset: 拼图最大显示偏移。
    /// - Returns: 与 Android 版本一致的拼图显示偏移。
    private func jigsawOffset(
        displayedOffset: CGFloat,
        sliderMaxOffset: CGFloat,
        jigsawMaxOffset: CGFloat
    ) -> CGFloat {
        guard sliderMaxOffset > 0, jigsawMaxOffset > 0 else { return 0 }
        let fraction = min(max(displayedOffset, 0) / sliderMaxOffset, 1)
        return fraction * jigsawMaxOffset
    }
}
