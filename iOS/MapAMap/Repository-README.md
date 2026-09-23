# DiminaMapAMap

Dimina 的可选高德地图 Swift Package。适配器源码由 [didi/dimina](https://github.com/didi/dimina) 生成，请在主仓库提交修改。

## 接入

在 Xcode 的 **Add Package Dependencies** 中添加本仓库的 Git URL，选择 **@VERSION@**，将 `DiminaMapAMap` product 链接到应用 target。也可在宿主的 `Package.swift` 中声明本仓库依赖。

该版本精确依赖 Dimina **@VERSION@**；SwiftPM 会下载 Release 中的高德 XCFramework，并验证 SHA-256。仅使用 Dimina 核心包不会引入本包。

将本包 `Sources/DiminaMapAMap/Resources/AMap.bundle` 添加到应用 target 的 **Copy Bundle Resources**。高德从应用主 bundle 查找资源，仅有 SwiftPM 资源 bundle 不足够；配置后请确认 CI 同样能找到该资源。

```swift
import Dimina
import DiminaMapAMap

// 在主 actor 上、打开小程序前调用。
DMPMapProviders.register("amap", provider: DiminaMapAMap.DMPAMapProvider(
    apiKey: apiKey,
    hasPrivacyConsent: { privacyConsentGranted }
))
```

平台 Key 和隐私授权状态由宿主提供。定位需要 `NSLocationWhenInUseUsageDescription`。不要重复链接其他版本的 MAMapKit 或 AMapFoundationKit。

## 平台与许可证

当前高德二进制支持 arm64 iOS 真机和 x86_64 iOS 模拟器，**不支持 arm64 模拟器**。Apple Silicon 请使用真机或 x86_64/Rosetta 模拟器。

适配器源码使用 Apache-2.0；高德二进制及资源遵循厂商条款，详见 `NOTICE` 和 `vendor.json`。

## 发布维护

不要在此仓库手工改适配器。主仓库的 `scripts/package-ios-amap.py` 生成源码仓库目录和二进制附件，再由 `scripts/publish-ios-amap-repository.sh` 同步并创建版本 tag。版本 tag 已存在时脚本会停止，不覆盖已发布版本。
