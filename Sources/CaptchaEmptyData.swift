import Foundation

/// AJ-Captcha check 成功时使用的空业务数据模型。
///
/// HTML 示例只判断 `repCode`，不解析 check 响应的 `repData`；该模型允许 repData 中存在任意字段。
struct CaptchaEmptyData: Decodable {
}
