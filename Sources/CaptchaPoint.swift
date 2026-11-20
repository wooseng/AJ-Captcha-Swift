import Foundation

/// 提交给服务端的滑动坐标。
struct CaptchaPoint: Codable, Equatable {

    /// 滑块在原始背景图坐标系中的横向偏移。
    let x: Double

    /// AJ-Captcha HTML 示例固定传入的纵向坐标。
    let y: Double

    /// 创建滑动坐标。
    ///
    /// - Parameters:
    ///   - x: 滑块横向偏移。
    ///   - y: 纵向坐标，当前协议固定为 5。
    init(x: Double, y: Double = 5) {
        self.x = x
        self.y = y
    }
}
