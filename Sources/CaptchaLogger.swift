import os

/// 组件内部控制台日志工具。
///
/// 使用方式：组件内部在状态变化和网络关键节点调用 `info` 或 `error`。
/// 日志只输出接口地址、状态码、数据长度等排查信息，不输出 token、secretKey、
/// Base64 图片内容或 captchaVerification，避免泄露敏感数据。
enum CaptchaLogger {

    /// 统一使用的系统日志对象。
    private static let logger = Logger(
        subsystem: "com.ajcaptcha.swift",
        category: "AJCaptcha"
    )

    /// 输出普通关键节点日志。
    ///
    /// - Parameter message: 已格式化的非敏感日志内容。
    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    /// 输出错误关键节点日志。
    ///
    /// - Parameter message: 已格式化的非敏感错误内容。
    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
