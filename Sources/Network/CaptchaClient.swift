import Foundation

/// AJ-Captcha 服务端请求客户端。
///
/// 使用方式：组件默认在 `CaptchaViewModel` 中创建；外部也可通过 `CaptchaService`
/// 协议替换整个请求实现。内置客户端保持与 `view/html/js/verify.js` 的
/// `getPictrue`、`checkPictrue` 一致，均为 POST JSON。
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
    /// - Parameters:
    ///   - captchaType: 验证码类型。
    ///   - clientUid: 客户端组件唯一标识，需要与后续 check 请求保持一致。
    /// - Returns: 背景图、拼图、token 与 AES 密钥。
    /// - Throws: URL 非法、网络失败、HTTP 非 2xx 或服务端返回非 `0000` 时抛出错误。
    func getCaptcha(
        captchaType: CaptchaType,
        clientUid: String
    ) async throws -> CaptchaData {
        let body = CaptchaGetRequest(captchaType: captchaType, clientUid: clientUid, ts: currentTimestamp)
        let response: CaptchaAPIResponse<CaptchaData> = try await post(
            path: configuration.getCaptchaEndpoint,
            body: body
        )
        return try validatedData(from: response)
    }

    /// 提交校验请求。
    ///
    /// - Parameters:
    ///   - captchaType: 验证码类型。
    ///   - pointJson: 组件加密或明文序列化后的滑动坐标。
    ///   - token: `/captcha/get` 返回的验证码令牌。
    ///   - clientUid: 客户端组件唯一标识，需要与 get 请求保持一致。
    /// - Returns: 服务端业务码与提示信息。
    /// - Throws: URL 非法、网络失败、HTTP 非 2xx 或响应格式错误时抛出错误。
    func check(
        captchaType: CaptchaType,
        pointJson: String,
        token: String,
        clientUid: String
    ) async throws -> CaptchaCheckResponse {
        let body = CaptchaCheckRequest(
            captchaType: captchaType,
            pointJson: pointJson,
            token: token,
            clientUid: clientUid,
            ts: currentTimestamp
        )

        let response: CaptchaAPIResponse<CaptchaEmptyData> = try await post(
            path: configuration.checkCaptchaEndpoint,
            body: body
        )
        return try validatedCode(from: response)
    }

    /// 拼接服务路径并发送 JSON POST 请求。
    ///
    /// - Parameters:
    ///   - path: 以 `/` 开头的接口路径，来自 `CaptchaConfiguration` 中的接口地址配置。
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
    ) throws -> CaptchaCheckResponse {
        CaptchaLogger.info("check business response code=\(response.repCode) message=\(response.repMsg ?? "nil")")
        guard response.repCode == "0000" else {
            throw CaptchaClientError.serverMessage(
                response.repMsg ?? configuration.localization.formatted(.unknownServerError, response.repCode)
            )
        }
        return CaptchaCheckResponse(repCode: response.repCode, repMsg: response.repMsg)
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

/// 内置 URLSession 客户端同时作为默认 `CaptchaService` 实现。
extension CaptchaClient: CaptchaService {
}
