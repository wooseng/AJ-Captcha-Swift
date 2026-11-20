import Foundation
import SwiftUI

/// 验证码组件状态机，负责加载、刷新、滑动校验与成功回调。
///
/// 使用方式：由 `CaptchaPopupView` 创建并持有；调用方只处理 `CaptchaResult` 回调。
@MainActor
final class CaptchaViewModel: ObservableObject {


    /// 当前展示阶段。
    @Published private(set) var phase: CaptchaPhase = .idle

    /// 当前背景图。
    @Published private(set) var backgroundImage: UIImage?

    /// 当前滑块拼图。
    @Published private(set) var jigsawImage: UIImage?

    /// 服务端返回的验证码令牌。
    private var token: String = ""

    /// 服务端返回的 AES 密钥。
    private var secretKey: String = ""

    /// 验证码请求实现；优先使用外部注入实现，否则使用内置 URLSession 客户端。
    private let service: CaptchaService

    /// 组件配置。
    private let configuration: CaptchaConfiguration

    /// 防止成功回调重复触发的标记。
    private var hasNotifiedSuccess = false

    /// 创建验证码状态机。
    ///
    /// - Parameter configuration: 组件配置，包含服务地址、请求实现与滑块提示文案。
    init(configuration: CaptchaConfiguration) {
        self.configuration = configuration
        self.service = configuration.service ?? CaptchaClient(configuration: configuration)
    }

    /// 滑动提示文案；外部覆盖文案优先，其次读取国际化配置。
    var sliderPrompt: String {
        configuration.sliderPrompt ?? configuration.localization[.sliderPrompt]
    }

    /// 当前组件国际化配置。
    var localization: CaptchaLocalization {
        configuration.localization
    }

    /// 当前组件误触阈值比例。
    var accidentalTouchThreshold: Double {
        configuration.accidentalTouchThreshold
    }

    /// 读取组件固定文案。
    ///
    /// - Parameter key: 组件国际化 key。
    /// - Returns: 调用方配置文案；未配置时返回简体中文。
    func localizedText(_ key: CaptchaLocalizationKey) -> String {
        configuration.localization[key]
    }

    /// 加载或刷新验证码。
    ///
    /// 该方法会重置图片、令牌与滑动状态，并自动处理并发刷新请求。
    func loadCaptcha() {
        guard phase != .loading else {
            CaptchaLogger.info("load ignored because phase is loading")
            return
        }
        CaptchaLogger.info(
            "load start service=\(configuration.service == nil ? "builtin" : "external") server=\(configuration.serverURL.absoluteString)"
        )
        phase = .loading
        token = ""
        secretKey = ""

        Task {
            do {
                let data = try await service.getCaptcha(
                    captchaType: configuration.captchaType,
                    clientUid: CaptchaClientIdentifier.shared.value
                )
                guard phase == .loading else {
                    CaptchaLogger.info("load result ignored because phase changed")
                    return
                }
                CaptchaLogger.info("load response received, start image decode")
                backgroundImage = CaptchaImageDecoder.image(fromBase64: data.originalImageBase64)
                jigsawImage = CaptchaImageDecoder.image(fromBase64: data.jigsawImageBase64)
                token = data.token
                secretKey = data.secretKey ?? ""

                if let backgroundImage = backgroundImage,
                   let jigsawImage = jigsawImage {
                    CaptchaLogger.info(
                        "image decode success original=\(Int(backgroundImage.size.width))x\(Int(backgroundImage.size.height)) jigsaw=\(Int(jigsawImage.size.width))x\(Int(jigsawImage.size.height))"
                    )
                    phase = .ready
                    CaptchaLogger.info("phase changed to ready")
                } else {
                    CaptchaLogger.error(
                        "image decode failed originalPresent=\(backgroundImage != nil) jigsawPresent=\(jigsawImage != nil)"
                    )
                    phase = .failure(configuration.localization[.imageError], autoRefreshes: false)
                }
            } catch {
                guard phase == .loading else {
                    CaptchaLogger.info("load error ignored because phase changed")
                    return
                }
                CaptchaLogger.error("load failed error=\(errorMessage(error))")
                phase = .failure(errorMessage(error), autoRefreshes: false)
            }
        }
    }

    /// 提交滑动结果给 `/captcha/check`。
    ///
    /// - Parameters:
    ///   - displayedOffset: 当前屏幕显示宽度下的滑块偏移。
    ///   - displayedImageWidth: 背景图当前显示宽度。
    ///   - onSuccess: check 成功后的唯一回调，参数中包含业务服务端需要的二次验证串。
    func check(
        displayedOffset: Double,
        displayedImageWidth: Double,
        onSuccess: @escaping (CaptchaResult) -> Void
    ) {
        guard phase == .ready, !token.isEmpty else {
            CaptchaLogger.error("check ignored phaseReady=\(phase == .ready) tokenPresent=\(!token.isEmpty)")
            return
        }
        CaptchaLogger.info("check start offset=\(displayedOffset) displayedWidth=\(displayedImageWidth)")
        phase = .checking

        Task {
            do {
                let payload = try makeCheckPayload(
                    displayedOffset: displayedOffset,
                    displayedImageWidth: displayedImageWidth
                )
                let response = try await service.check(
                    captchaType: configuration.captchaType,
                    pointJson: payload.encryptedPointJSON,
                    token: token,
                    clientUid: CaptchaClientIdentifier.shared.value
                )
                CaptchaLogger.info(
                    "check business response code=\(response.repCode) message=\(response.repMsg ?? "nil")"
                )
                guard response.repCode == "0000" else {
                    throw CaptchaClientError.serverMessage(
                        response.repMsg ?? configuration.localization.formatted(.unknownServerError, response.repCode)
                    )
                }

                phase = .success
                CaptchaLogger.info("phase changed to success")

                guard !hasNotifiedSuccess else {
                    CaptchaLogger.info("success callback ignored because it has already been sent")
                    return
                }
                hasNotifiedSuccess = true
                CaptchaLogger.info("success callback start")
                onSuccess(
                    CaptchaResult(
                        captchaVerification: payload.captchaVerification,
                        token: token
                    )
                )
            } catch {
                CaptchaLogger.error("check failed error=\(errorMessage(error))")
                phase = .failure(errorMessage(error), autoRefreshes: true)
            }
        }
    }

    /// 生成提交给服务端的校验参数。
    ///
    /// - Parameters:
    ///   - displayedOffset: 当前屏幕显示宽度下的滑块偏移。
    ///   - displayedImageWidth: 背景图当前显示宽度。
    /// - Returns: 加密或明文坐标 JSON 与业务服务端需要的二次验证参数。
    /// - Throws: JSON 序列化或 AES 加密失败时抛出错误。
    private func makeCheckPayload(
        displayedOffset: Double,
        displayedImageWidth: Double
    ) throws -> (
        encryptedPointJSON: String,
        captchaVerification: String
    ) {
        // HTML 示例使用 620 作为滑动坐标换算基准，不能按底图原始宽度直接换算。
        let scale = displayedImageWidth > 0 ? 620 / displayedImageWidth : 1
        let point = CaptchaPoint(x: displayedOffset * scale)
        CaptchaLogger.info(
            "check request prepare displayedOffset=\(displayedOffset) displayedWidth=\(displayedImageWidth) scaledX=\(point.x) encrypted=\(!secretKey.isEmpty)"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let pointData = try encoder.encode(point)
        guard let pointJSON = String(data: pointData, encoding: .utf8) else {
            throw CaptchaClientError.invalidResponse
        }

        let encryptedPointJSON = secretKey.isEmpty
            ? pointJSON
            : try CaptchaAES.encrypt(pointJSON, key: secretKey)
        let verificationPlain = "\(token)---\(pointJSON)"
        let captchaVerification = secretKey.isEmpty
            ? verificationPlain
            : try CaptchaAES.encrypt(verificationPlain, key: secretKey)
        return (encryptedPointJSON, captchaVerification)
    }

    /// 将内部错误转换为当前语言下的 UI 文案。
    ///
    /// - Parameter error: 网络或加密错误。
    /// - Returns: 用于失败状态展示的文案。
    private func errorMessage(_ error: Error) -> String {
        if let clientError = error as? CaptchaClientError {
            return clientError.message(in: configuration.localization)
        }
        return error.localizedDescription
    }
}
