# DiminaMapAMap（Swift Package）

Dimina 主仓库提供两个 Swift Package product：`Dimina` 核心 SDK 和可选的 `DiminaMapAMap` 高德地图适配器。

## 通过同一仓库接入

1. 在 Xcode **Add Package Dependencies** 中添加 `https://github.com/didi/dimina.git`，选择包含地图 product 的版本或分支。
2. 将 `DiminaMapAMap` product 链接到应用 target，它会依赖同一份 `Dimina` 核心 target。
3. 从 SwiftPM 下载的 `MAMapKit.xcframework/ios-arm64/MAMapKit.framework/AMap.bundle` 中取得资源，将其加入应用 target 的 **Copy Bundle Resources**。Xcode 下载的 XCFramework 位于 DerivedData 的 `SourcePackages/artifacts` 下；也可从 Release 的本地包中取得同一资源，保存在宿主项目中供 CI 使用。高德从应用主 bundle 查找资源，仅有框架内资源不足够。
4. 在主 actor 上、打开小程序前注册：

```swift
import Dimina
import DiminaMapAMap

DMPMapProviders.register("amap", provider: DiminaMapAMap.DMPAMapProvider(
    apiKey: apiKey,
    hasPrivacyConsent: { privacyConsentGranted }
))
```

Key 和实际隐私授权由宿主提供；定位需要 `NSLocationWhenInUseUsageDescription`。不要重复链接其他版本的 MAMapKit 或 AMapFoundationKit。

只选择 `Dimina` 不会链接高德 SDK；同一个 package 的二进制 target 在 SwiftPM 解析时仍可能被下载。

**版本边界：** 已发布的 `v1.7.5` tag 尚未包含主仓库地图 product。新增 manifest 合入并推送后，可暂时选择包含该改动的分支或 commit；正式版本接入需使用后续包含该改动的 tag。不能仅靠补充 Release 附件改变旧 tag 中的 Package.swift。

## 离线接入

从 Dimina Release 下载 `DiminaMapAMap-<version>.zip` 并解压，通过 **Add Package Dependencies → Add Local** 添加，链接 `DiminaMapAMap` product。资源位于 `Sources/DiminaMapAMap/Resources/AMap.bundle`，同样需要复制到宿主主 bundle。

当前固定的高德官方库支持 arm64 iOS 真机和 x86_64 iOS 模拟器，不包含 arm64 模拟器架构。Apple Silicon 请使用真机或 x86_64/Rosetta 模拟器。

## 发布维护

```sh
python3 scripts/package-ios-amap.py --version <core-sdk-version> --output /tmp/dimina-map-release
```

脚本校验厂商 SHA-256，生成本地 Swift Package ZIP 和两个 XCFramework ZIP。Release 流程构建本地包和主仓库地图 product，再附加产物；不会覆盖已存在的二进制附件。

根目录 `Package.swift` 固定远程二进制 URL 和 checksum；当前复用 `v1.7.5` Release 的高德附件。核心版本更新不必重新发布相同的高德二进制。升级高德版本时，应先在新的不可变 URL 发布并验证 XCFramework，再更新 manifest 的 URL 和 `swift package compute-checksum` 结果，最后发布引用该 manifest 的核心版本 tag。
