import Foundation

/// AJ-Captcha 标准响应包装。
struct CaptchaAPIResponse<Data: Decodable>: Decodable {

    /// 业务状态码，`0000` 表示成功。
    let repCode: String

    ///失败时的服务端提示信息。
    let repMsg: String?

    /// 成功时的业务数据。
    let repData: Data?
}
