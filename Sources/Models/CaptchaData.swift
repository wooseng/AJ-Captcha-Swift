import Foundation

/// `/captcha/get` 响应中的验证码图片与密钥数据。
///
/// 使用方式：内置网络实现会自动解码；外部实现收到自定义响应后，可转换为该模型交给组件渲染与校验。
public struct CaptchaData: Decodable {

    /// 背景图 Base64 字符串。
    public let originalImageBase64: String

    /// 滑块拼图 Base64 字符串。
    public let jigsawImageBase64: String

    /// 服务端生成的验证码令牌。
    public let token: String

    /// 服务端下发的 AES 密钥；关闭加密或值为 null 时传 nil。
    public let secretKey: String?

    /// 创建验证码数据。
    ///
    /// - Parameters:
    ///   - originalImageBase64: 背景图 Base64 字符串。
    ///   - jigsawImageBase64: 滑块拼图 Base64 字符串。
    ///   - token: 服务端生成的验证码令牌。
    ///   - secretKey: 服务端下发的 AES 密钥。
    public init(
        originalImageBase64: String,
        jigsawImageBase64: String,
        token: String,
        secretKey: String?
    ) {
        self.originalImageBase64 = originalImageBase64
        self.jigsawImageBase64 = jigsawImageBase64
        self.token = token
        self.secretKey = secretKey
    }
}
