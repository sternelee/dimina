# Dimina 共享资源

`shared/` 保存仓库示例工程共同使用的小程序包和 JSSDK 产物。Android、iOS 与 Harmony 在构建时从这里复制资源，避免在三个平台目录中维护重复文件。

这套目录是 Dimina 仓库的资源源文件，不是业务宿主必须采用的发布结构。接入方可以按各平台 README 将固定版本的资源放入自己的工程，或接入单独的包管理流程。

## 目录结构

```text
shared/
├── jsapp/
│   └── <appId>/
│       ├── config.json
│       └── <appId>.zip
└── jssdk/
    ├── config.json
    └── main.zip
```

- `jsapp/`：编译后的小程序包。每个目录以 `appId` 命名，并包含包配置和同名 zip。
- `jssdk/`：Service、Render 与相关前端运行时的打包产物。

## 生成资源

在 `fe/` 安装依赖并完成编译后运行：

```sh
cd fe
pnpm compile
pnpm build
pnpm generate:app
pnpm generate:sdk
```

`generate:app` 会更新 `shared/jsapp`，`generate:sdk` 会更新 `shared/jssdk`。两个命令都会递增对应资源的版本号；只验证前端代码时，不要无意提交生成资源的版本变化。

## 各端复制位置

| 平台 | 小程序资源 | JSSDK 资源 | 仓库内复制入口 |
| --- | --- | --- | --- |
| Android | `android/app/src/main/assets/jsapp/` | `android/dimina/src/main/assets/jssdk/` | `copySharedJsappToAssets`、`copySharedJssdkToAssets` Gradle 任务 |
| iOS | `iOS/dimina/Resources/JsApp.bundle/` | `iOS/dimina/Resources/JsSdk.bundle/` | Xcode Build Phase 调用 `iOS/copy-shared-resources.sh` |
| Harmony | `harmony/entry/src/main/resources/rawfile/jsapp/` | `harmony/dimina/src/main/resources/rawfile/jssdk/` | `harmony/hvigorfile.ts` 配置阶段回调 |

这些复制入口已经配置在仓库示例工程中，无需再次手动添加 Build Phase 或构建任务。

## 添加小程序包

新增包时，在 `shared/jsapp/` 下创建以 `appId` 命名的目录：

```text
shared/jsapp/wx92269e3b2f304afc/
├── config.json
└── wx92269e3b2f304afc.zip
```

`config.json` 中的 `appId` 必须与目录名和 zip 文件名一致。更新已有包时还要递增 `versionCode`，否则原生 SDK 可能继续使用沙盒中的旧版本。
