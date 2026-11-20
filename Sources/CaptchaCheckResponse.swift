import Foundation

/// AJ-Captcha check 接口给外部请求实现返回的标准业务结果。
///
/// 使用方式：外部实现负责把自定义网络响应转换为该模型；组件只根据 `repCode`
/// 判断最终校验是否成功。
public struct CaptchaCheckResponse {

    /// AJ-Captcha 业务状态码，`0000` 表示校验成功。
    public let repCode: String

    /// 服务端失败提示。
    public let repMsg: String?

    /// 创建 check 响应结果。
    ///
    /// - Parameters:
    ///   - repCode: AJ-Captcha 业务状态码。
    ///   - repMsg: 服务端失败提示。
    public init(
        repCode: String,
        repMsg: String? = nil
    ) {
        self.repCode = repCode
        self.repMsg = repMsg
    }
}
