import CommonCrypto
import Foundation

/// AJ-Captcha 前端协议使用的 AES-128-ECB 加密工具。
///
/// 使用方式：组件内部自动调用，调用方无需接触明文坐标或密钥。
enum CaptchaAES {

    /// 按服务端协议加密字符串。
    ///
    /// - Parameters:
    ///   - plaintext: 待加密字符串，例如滑动坐标 JSON 或 `token---坐标JSON`。
    ///   - key: `/captcha/get` 返回的 16 位 AES 密钥。
    /// - Returns: Base64 编码后的密文。
    /// - Throws: 输入或密钥长度非法、系统加密失败时抛出错误。
    static func encrypt(_ plaintext: String, key: String) throws -> String {
        let keyBytes = Array(key.utf8)
        let input = Data(plaintext.utf8)
        let capacity = input.count + kCCBlockSizeAES128
        var output = Data(count: capacity)
        var outputLength = 0

        let status = output.withUnsafeMutableBytes { outputPointer -> CCCryptorStatus in
            input.withUnsafeBytes { inputPointer in
                keyBytes.withUnsafeBufferPointer { keyPointer in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionECBMode | kCCOptionPKCS7Padding),
                        keyPointer.baseAddress,
                        keyBytes.count,
                        nil,
                        inputPointer.baseAddress,
                        input.count,
                        outputPointer.baseAddress,
                        outputPointer.count,
                        &outputLength
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw CaptchaClientError.aes(status: Int(status))
        }

        output.removeSubrange(outputLength..<output.count)
        return output.base64EncodedString()
    }
}
