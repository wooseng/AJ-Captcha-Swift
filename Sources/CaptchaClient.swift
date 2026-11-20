import Foundation

/// AJ-Captcha 服务端请求客户端。
///
/// 使用方式：`CaptchaViewModel` 内部创建并调用；请求实现保持与 `view/html/js/verify.js`
/// 的 `getPictrue`、`checkPictrue` 一致，均为 POST JSON。
final class CaptchaClient {

    /// 当前组件配置，包含服务根地址。
    private let configuration: CaptchaConfiguration

    /// 执行网络请求的会话。
    private let urlSession: URLSession

    /// 创建请求客户端。
    ///
    /// - Parameters:
    ///   - configuration: 组件配置，`serverURL` 必须指向 AJ-Captcha 服务根地址。
    ///   - urlSession: 网络会话；默认使用共享会话，参数保留给内部测试与替换场景。
    init(
        configuration: CaptchaConfiguration,
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    /// 获取滑动拼图验证码。
    ///
    /// - Parameter clientUid: 客户端组件唯一标识，需要与后续 check 请求保持一致。
    /// - Returns: 背景图、拼图、token 与 AES 密钥。
    /// - Throws: URL 非法、网络失败、HTTP 非 2xx 或服务端返回非 `0000` 时抛出错误。
    func getCaptcha(clientUid: String) async throws -> CaptchaData {
        let body = CaptchaGetRequest(captchaType: configuration.captchaType, clientUid: clientUid, ts: currentTimestamp)
        let response: CaptchaAPIResponse<CaptchaData> = try await post(
            path: "/captcha/get",
            body: body
        )
        return try validatedData(from: response)
    }

    /// 校验滑动结果并生成二次验证参数。
    ///
    /// - Parameters:
    ///   - token: `/captcha/get` 返回的验证码令牌。
    ///   - secretKey: 服务端下发的 AES 密钥；为空时按协议提交明文坐标。
    ///   - displayedOffset: 当前屏幕显示宽度下的滑块偏移。
    ///   - displayedImageWidth: 背景图当前显示宽度，组件按 HTML 协议使用 620 除以该值换算坐标。
    ///   - clientUid: 客户端组件唯一标识，需要与 get 请求保持一致。
    /// - Returns: check 成功后的二次验证参数。
    /// - Throws: 加密、网络、HTTP 或服务端校验失败时抛出错误。
    func check(
        token: String,
        secretKey: String,
        displayedOffset: Double,
        displayedImageWidth: Double,
        clientUid: String
    ) async throws -> String {
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

        let encryptedPoint = secretKey.isEmpty
            ? pointJSON
            : try CaptchaAES.encrypt(pointJSON, key: secretKey)
        let verificationPlain = "\(token)---\(pointJSON)"
        let captchaVerification = secretKey.isEmpty
            ? verificationPlain
            : try CaptchaAES.encrypt(verificationPlain, key: secretKey)
        let body = CaptchaCheckRequest(
            captchaType: configuration.captchaType,
            pointJson: encryptedPoint,
            token: token,
            clientUid: clientUid,
            ts: currentTimestamp
        )

        let response: CaptchaAPIResponse<CaptchaEmptyData> = try await post(
            path: "/captcha/check",
            body: body
        )
        _ = try validatedCode(from: response)
        return captchaVerification
    }

    /// 拼接服务路径并发送 JSON POST 请求。
    ///
    /// - Parameters:
    ///   - path: 以 `/` 开头的接口路径，例如 `/captcha/get`。
    ///   - body: 符合 AJ-Captcha 协议的请求体。
    /// - Returns: 解码后的服务端响应。
    /// - Throws: URL 非法、网络失败、HTTP 非 2xx 或响应格式错误时抛出错误。
    private func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body
    ) async throws -> Response {
        let request = try makeRequest(path: path, body: body)
        CaptchaLogger.info("network start path=\(path) url=\(request.url?.absoluteString ?? "nil")")
        let data: Data
        let httpResponse: URLResponse
        do {
            (data, httpResponse) = try await urlSession.data(for: request)
        } catch {
            CaptchaLogger.error("network transport failed path=\(path) error=\(error.localizedDescription)")
            throw CaptchaClientError.transport(error.localizedDescription)
        }

        guard let http = httpResponse as? HTTPURLResponse else {
            throw CaptchaClientError.invalidResponse
        }
        CaptchaLogger.info("network received path=\(path) status=\(http.statusCode) bytes=\(data.count)")
        guard (200..<300).contains(http.statusCode) else {
            CaptchaLogger.error("network http failed path=\(path) status=\(http.statusCode)")
            throw CaptchaClientError.httpError(statusCode: http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            CaptchaLogger.info("network decode success path=\(path) type=\(String(describing: Response.self))")
            return decoded
        } catch {
            CaptchaLogger.error("network decode failed path=\(path) error=\(error.localizedDescription)")
            throw CaptchaClientError.invalidResponse
        }
    }

    /// 创建 JSON POST 请求。
    ///
    /// - Parameters:
    ///   - path: 接口路径。
    ///   - body: 请求体对象。
    /// - Returns: 已设置 Content-Type 的 URLRequest。
    private func makeRequest<Body: Encodable>(
        path: String,
        body: Body
    ) throws -> URLRequest {
        let base = configuration.serverURL.absoluteString
        let normalizedBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        guard let url = URL(string: normalizedBase + path) else {
            throw CaptchaClientError.invalidServerURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    /// 校验 AJ-Captcha 标准响应并返回业务数据。
    ///
    /// - Parameter response: `/captcha/get` 或 `/captcha/check` 的响应包装。
    /// - Returns: `repCode` 为 `0000` 时的业务数据。
    /// - Throws: 服务端返回失败或缺少数据时抛出错误。
    private func validatedCode(
        from response: CaptchaAPIResponse<CaptchaEmptyData>
    ) throws {
        CaptchaLogger.info("check business response code=\(response.repCode) message=\(response.repMsg ?? "nil")")
        guard response.repCode == "0000" else {
            throw CaptchaClientError.serverMessage(
                response.repMsg ?? configuration.localization.formatted(.unknownServerError, response.repCode)
            )
        }
    }

    /// 校验 get 接口响应并返回业务数据。
    private func validatedData(
        from response: CaptchaAPIResponse<CaptchaData>
    ) throws -> CaptchaData {
        CaptchaLogger.info(
            "get business response code=\(response.repCode) message=\(response.repMsg ?? "nil") dataPresent=\(response.repData != nil)"
        )
        guard response.repCode == "0000" else {
            throw CaptchaClientError.serverMessage(
                response.repMsg ?? configuration.localization.formatted(.unknownServerError, response.repCode)
            )
        }
        guard let data = response.repData else {
            CaptchaLogger.error("get business data missing")
            throw CaptchaClientError.invalidResponse
        }
        CaptchaLogger.info(
            "get data valid originalLength=\(data.originalImageBase64.count) jigsawLength=\(data.jigsawImageBase64.count) tokenPresent=\(!data.token.isEmpty) secretKeyPresent=\(!(data.secretKey ?? "").isEmpty)"
        )
        return data
    }

    /// 当前毫秒时间戳，对应 HTML 示例中的 `Date.now()`。
    private var currentTimestamp: Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}
