# AJ-Captcha-Swift

基于 [AJ-Captcha](https://gitee.com/belief-team/captcha) 服务端协议实现的 iOS SwiftUI 滑动拼图验证码组件。

## 环境要求

- iOS 15.0+
- Swift 5.9+
- Xcode 15+
- 服务端已接入 AJ-Captcha，并暴露 `/captcha/get` 与 `/captcha/check`

## 功能说明

- 支持 SPM 与 CocoaPods 接入
- SwiftUI 全屏弹窗：半透明黑色背景、居中白色容器
- 外部配置服务地址与滑动条提示；提示默认为“向右滑动完成验证”
- 组件内部完成 `/captcha/get`、坐标换算、AES-128-ECB 加密、`/captcha/check`
- 仅在 `/captcha/check` 返回 `repCode == "0000"` 后回调二次验证参数
- 校验失败、刷新、网络错误均在组件内部处理，不向业务层回调失败

## 国际化配置

组件固定文案支持外部注入，也支持读取系统 `Localizable.strings`。所有 key 均使用 `aj_captcha.` 前缀；读取优先级为：`CaptchaLocalization.overrides` → 系统 `Localizable.strings` → 组件内置简体中文。服务端动态返回的 `repMsg` 仍按服务端内容展示。

```swift
let localization = CaptchaLocalization(overrides: [
    .title: "Security verification",
    .sliderPrompt: "Slide right to verify",
    .loading: "Loading captcha...",
    .retry: "Retry",
    .success: "Verification passed"
])

let configuration = CaptchaConfiguration(
    serverURL: URL(string: "https://example.com/captcha-api")!,
    localization: localization
)
```

`sliderPrompt` 参数保留为单条文案覆盖项，优先级高于 `.sliderPrompt` 国际化 key。

宿主 App 的 `Localizable.strings` 可以直接配置组件 key：

```strings
"aj_captcha.title" = "Security verification";
"aj_captcha.slider_prompt" = "Slide right to verify";
"aj_captcha.loading" = "Loading captcha...";
```

如需读取非主 bundle 的字符串资源，可以初始化 `CaptchaLocalization` 时传入 `bundle`。

| Key | 简体中文回退 |
| --- | --- |
| `aj_captcha.title` | 请完成安全验证 |
| `aj_captcha.slider_prompt` | 向右滑动完成验证 |
| `aj_captcha.loading` | 验证码加载中... |
| `aj_captcha.retry` | 重新加载 |
| `aj_captcha.success` | 验证成功 |
| `aj_captcha.failure` | 验证失败 |
| `aj_captcha.close` | 关闭验证码 |
| `aj_captcha.refresh` | 刷新验证码 |
| `aj_captcha.error.image` | 验证码图片解析失败 |
| `aj_captcha.error.aes` | 验证码加密失败 |
| `aj_captcha.error.invalid_server` | 验证码服务地址无效 |
| `aj_captcha.error.invalid_response` | 验证码服务响应异常 |
| `aj_captcha.error.http` | 验证码服务请求失败（HTTP %d） |
| `aj_captcha.error.unknown_server` | 验证码服务返回未知错误（%@） |
| `aj_captcha.error.transport` | 验证码网络请求失败（%@） |

## SPM 接入

在 Xcode 的 `Package Dependencies` 中添加：

```text
https://github.com/wooseng/AJ-Captcha-Swift.git
```

或修改 `Package.swift`：

```swift
.package(url: "https://github.com/wooseng/AJ-Captcha-Swift.git", from: "0.1.0")
```

业务代码：

```swift
import AJCaptcha
import SwiftUI

struct LoginView: View {
    @State private var isCaptchaPresented = false

    var body: some View {
        Button("开始验证") {
            isCaptchaPresented = true
        }
        .captchaPopup(
            isPresented: $isCaptchaPresented,
            configuration: CaptchaConfiguration(
                serverURL: URL(string: "https://example.com/captcha-api")!
            )
        ) { result in
            // 将 result.captchaVerification 原样传给业务服务端
            login(captchaVerification: result.captchaVerification)
        }
    }
}
```

## CocoaPods 接入

```ruby
pod 'AJCaptcha', :git => 'https://github.com/wooseng/AJ-Captcha-Swift.git'
```

执行 `pod install` 后同样使用上述 SwiftUI API。

## 参数说明

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `serverURL` | `URL` | AJ-Captcha 服务根地址；组件自动拼接 `/captcha/get` 与 `/captcha/check` |
| `sliderPrompt` | `String` | 滑动条内提示，默认“向右滑动完成验证” |
| `onSuccess` | `(CaptchaResult) -> Void` | `/captcha/check` 成功后的回调，只回调一次 |
| `result.captchaVerification` | `String` | 业务服务端需要的二次验证参数 |
| `result.token` | `String` | 本次验证码令牌，便于日志排查 |

## Demo

根目录 `DemoApp.swift` 是 Demo App 源码，默认传入本地服务地址 `http://localhost:8080`。`AJCaptchaDemo.xcodeproj` 通过 Xcode 的 Local Package 配置引用根目录 SPM 包，并依赖 `AJCaptcha` 产品；组件的 `Package.swift` 只描述库本身，不包含 Demo 目标。用 Xcode 打开 `AJCaptchaDemo.xcodeproj`，选择真机或通用 iOS 设备运行。

## 协议行为

实现参考 AJ-Captcha 仓库 `view/html` 示例：

1. POST `serverURL + /captcha/get`
2. 解析背景图、拼图、`token`、`secretKey`
3. 用户松手后把屏幕偏移换算为原图坐标，并生成 `{"x":xx,"y":5}`
4. `secretKey` 非空时使用 AES-128-ECB/PKCS7 加密 `pointJson`
5. POST `serverURL + /captcha/check`
6. `repCode == "0000"` 时回调 `captchaVerification`；业务服务端可使用该值完成二次校验
