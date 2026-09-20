# DiminaMapAMap（Swift Package）

为 Dimina 提供可选的高德地图能力。生成的发布 ZIP 包包含独立 Swift Package、固定版本的高德官方 XCFramework 和 `AMap.bundle`。地图包依赖同版本的 Dimina；仅安装核心包不会引入高德 SDK。

1. 从对应的 GitHub Release 下载 `DiminaMapAMap-<version>.zip` 并解压。
2. 在 Xcode 中选择 **Add Package Dependencies → Add Local**，选中解压目录，将 `DiminaMapAMap` 产品链接到应用 target。请将包目录保存在项目或依赖存储中，供 CI 构建使用。
3. 将 `Sources/DiminaMapAMap/Resources/AMap.bundle` 加入应用 target 的 **Copy Bundle Resources**。高德从应用主 bundle 查找此资源，仅有 SwiftPM 资源 bundle 并不足够。
4. 注册 provider 前，准备好平台 Key、实际的隐私授权状态和定位权限：

```swift
import Dimina
import DiminaMapAMap

DMPMapProviders.register("amap", provider: DiminaMapAMap.DMPAMapProvider(
    apiKey: apiKey,
    hasPrivacyConsent: { privacyConsentGranted }
))
```

请在主 actor 上注册。使用定位功能时，需配置 `NSLocationWhenInUseUsageDescription`。不要再手动链接其他版本的 MAMapKit 或 AMapFoundationKit。

当前固定版本的官方库支持 **arm64 iOS 真机和 x86_64 iOS 模拟器**，不包含 arm64 模拟器架构。在 Apple Silicon 上请使用 x86_64/Rosetta 模拟器或真机，不能将 arm64 真机二进制用于模拟器。

维护者可在 macOS 上执行以下命令生成包：

```sh
python3 scripts/package-ios-amap.py --version <core-sdk-version> --output /tmp/dimina-map-release
```

脚本会校验固定的 SHA-256，按平台拆分官方多架构 Framework，并生成明确声明二进制 target 依赖的 Swift Package。脚本本身不会上传文件；Release 工作流会将生成的 ZIP 附加到新的 GitHub Release。已有 tag 不会自动补发适配器。
