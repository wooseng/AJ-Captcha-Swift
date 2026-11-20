import Foundation

/// `/captcha/get` 响应中的验证码图片与密钥数据。
struct CaptchaData: Decodable {

    /// 背景图 Base64 字符串。
    let originalImageBase64: String

    /// 滑块拼图 Base64 字符串。
    let jigsawImageBase64: String

    /// 服务端生成的验证码令牌。
    let token: String

    /// 服务端下发的 AES 密钥；关闭加密或值为 null 时按空字符串处理。
    let secretKey: String?
}
