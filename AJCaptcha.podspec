# AJ-Captcha Swift 组件的 CocoaPods 描述文件。
#
# 使用方式：在 Podfile 中添加 `pod 'AJCaptcha'` 后执行 `pod install`。
# 源码位置：仓库根目录下的 Sources；最低系统版本 iOS 15；Swift 版本 5.9 及以上。

Pod::Spec.new do |s|
  s.name                  = 'AJCaptcha'
  s.version               = '0.1.0'
  s.summary               = 'AJ-Captcha 的 SwiftUI 端滑动验证码组件。'
  s.description           = '基于 AJ-Captcha 服务端协议实现，组件内部完成获取、滑动校验与 AES 加密，check 成功后回调二次验证参数。'
  s.homepage              = 'https://github.com/wooseng/AJ-Captcha-Swift'
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { 'wooseng' => 'wooseng@users.noreply.github.com' }
  s.source                = { :git => 'https://github.com/wooseng/AJ-Captcha-Swift.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.swift_versions        = ['5.9']
  s.source_files          = 'Sources/**/*.swift'
end
