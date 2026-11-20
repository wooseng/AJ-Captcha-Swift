import Foundation

/// 组件对外暴露的国际化 key。
    ///
    /// `rawValue` 是接入方国际化配置表使用的完整 key；格式化类文案支持 `%@`、`%d` 等系统格式化占位符。
public enum CaptchaLocalizationKey: String, CaseIterable, Sendable {

    /// 弹窗标题。
    case title = "aj_captcha.title"

    /// 滑动条默认提示。
    case sliderPrompt = "aj_captcha.slider_prompt"

    /// 加载中文案。
    case loading = "aj_captcha.loading"

    /// 加载失败后的重试按钮文案。
    case retry = "aj_captcha.retry"

    /// 校验成功提示。
    case success = "aj_captcha.success"

    /// 校验失败提示。
    case failure = "aj_captcha.failure"

    /// 关闭按钮无障碍文案。
    case close = "aj_captcha.close"

    /// 刷新按钮无障碍文案。
    case refresh = "aj_captcha.refresh"

    /// 图片解析失败文案。
    case imageError = "aj_captcha.error.image"

    /// AES 加密失败文案。
    case aesError = "aj_captcha.error.aes"

    /// 服务地址无效文案。
    case invalidServerError = "aj_captcha.error.invalid_server"

    /// 服务响应结构异常文案。
    case invalidResponseError = "aj_captcha.error.invalid_response"

    /// HTTP 请求失败文案；格式化参数为状态码。
    case httpError = "aj_captcha.error.http"

    /// 服务端未知错误文案；格式化参数为业务状态码。
    case unknownServerError = "aj_captcha.error.unknown_server"

    /// 网络传输错误文案；格式化参数为系统错误描述。
    case transportError = "aj_captcha.error.transport"
    }
