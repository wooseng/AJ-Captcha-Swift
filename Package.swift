// swift-tools-version: 5.9
//
// AJCaptcha Swift Package 描述文件。
//
// 本文件只负责发布组件库；根目录 Demo App 的 SPM 依赖由 AJCaptchaDemo.xcodeproj
// 通过 Xcode 的 Local Package 配置引入，避免 Demo 目标混入组件包描述。
//
// 使用方式：在其他 SPM 项目中添加本仓库地址，并选择 AJCaptcha 产品。

import PackageDescription

let package = Package(
    name: "AJCaptcha",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AJCaptcha",
            targets: ["AJCaptcha"]
        )
    ],
    targets: [
        .target(
            name: "AJCaptcha",
            path: "Sources"
        )
    ]
)
