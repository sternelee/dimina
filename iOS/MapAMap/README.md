# DiminaMapAMap（Swift Package）

为 Dimina 提供可选的高德地图能力。生成的发布 ZIP 包包含独立 Swift Package、固定版本的高德官方 XCFramework 和 `AMap.bundle`。地图包依赖同版本的 Dimina；仅安装核心包不会引入高德 SDK。

推荐通过独立仓库 [didi/dimina-map-amap](https://github.com/didi/dimina-map-amap) 接入：在 Xcode 的 **Add Package Dependencies** 中输入 `https://github.com/didi/dimina-map-amap.git`，选择与核心 SDK 一致的版本并链接 `DiminaMapAMap` product。SwiftPM 会从 Dimina Release 下载高德 XCFramework，并验证 SHA-256。

需要离线接入时，仍可使用本地包：

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

## 独立仓库发布

同一次生成还会输出 `DiminaMapAMap-<version>-repository/`（仓库源码）、其 ZIP，以及两个 `*.xcframework.zip`。二进制 ZIP 放在 Dimina 对应版本的 GitHub Release；源码目录中的 `Package.swift` 使用远程 URL 和校验值，不含二进制文件。

先完成本地包的 iOS 构建，再上传两个二进制 ZIP，最后同步源码仓库：

```sh
bash scripts/publish-ios-amap-repository.sh \
  /tmp/dimina-map-release/DiminaMapAMap-<version>-repository \
  didi/dimina-map-amap <version>
```

同步脚本先执行真实的远程 SwiftPM 依赖解析，再普通推送源码和版本 tag；不会覆盖已存在的 tag。目标仓库必须事先创建。源码只在主仓库维护，独立仓库由发布流程生成。

自动同步需在主仓库配置 Actions variable `DIMINA_MAP_AMAP_REPOSITORY=didi/dimina-map-amap` 和 secret `DIMINA_MAP_AMAP_TOKEN`（对目标仓库拥有 Contents 读写权限的凭据）。默认 `GITHUB_TOKEN` 仅对当前仓库授权，不能用于写入另一个仓库。未配置时，Release 仍生成并上传分发文件，日志提示跳过跨仓库同步。
