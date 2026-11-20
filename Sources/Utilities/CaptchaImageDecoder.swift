import UIKit

/// 从服务返回的 Base64 字符串解析图片。
enum CaptchaImageDecoder {

        /// 解析图片。
        ///
        /// - Parameter base64: 服务端返回的 Base64，可带 `data:image/png;base64,` 前缀。
        /// - Returns: 解析成功时返回图片，否则返回 nil。
        static func image(fromBase64 base64: String) -> UIImage? {
            let normalized = base64
                .replacingOccurrences(of: "data:image/png;base64,", with: "")
                .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            guard let data = Data(base64Encoded: normalized) else { return nil }
            return UIImage(data: data)
        }
}
