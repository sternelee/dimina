# Dimina 共享资源

此目录包含被多个 Dimina 平台实现（Android、iOS、Harmony）共同使用的共享资源。

## 问题背景

Dimina 作为一个跨平台的小程序框架，同时支持 Android 、iOS 和 Harmony 操作系统。在原有的代码仓库结构中，小程序资源文件和 SDK 文件存在重复：

- Android 平台: 
  - 小程序资源：`app/src/main/assets/jsapp/[appId]/`
  - SDK 资源：`dimina/src/main/assets/jssdk/`
- Harmony 平台: 
  - 小程序资源：`entry/src/main/resources/rawfile/jsapp/[appId]/`
  - SDK 资源：`dimina/src/main/resources/rawfile/jssdk/`

这种重复导致以下问题：
1. 维护成本高（需要在多处更新相同文件）
2. 仓库体积增大
3. 平台之间可能出现资源不一致

## 优化方案

为解决上述问题，我们实施了共享资源方案，将所有平台的小程序资源统一管理在一个共享目录中，并在构建过程中自动复制到各平台特定位置。

## 目录结构

- `jsapp/`：包含被 Android 和 Harmony 平台共同使用的小程序包
  - `[appId]/`：每个小程序的目录，以其唯一的 appId 命名
    - `config.json`：小程序的配置文件
    - `[appId].zip`：编译好的小程序包
- `jssdk/`：包含被 Android 和 Harmony 平台共同使用的 SDK 文件
  - `config.json`：SDK 的配置文件
  - `main.zip`：SDK 核心文件

```
/Users/doslin/Dev/GitHub/dimina/
├── shared/
│   ├── jsapp/
│   │   ├── [appId1]/
│   │   │   ├── config.json
│   │   │   └── [appId1].zip
│   │   └── [appId2]/
│   │       ├── config.json
│   │       └── [appId2].zip
│   └── jssdk/
│       ├── config.json
│       └── main.zip
```

## 使用方法

此目录中的资源在构建过程中会自动复制到相应的平台特定位置：

### 小程序资源 (jsapp)

- Android：`app/src/main/assets/jsapp/`
- Harmony：`entry/src/main/resources/rawfile/jsapp/`

### SDK 资源 (jssdk)

- Android：`dimina/src/main/assets/jssdk/`
- Harmony：`dimina/src/main/resources/rawfile/jssdk/`

### 资源管理工具

我们提供了资源管理工具 `shared/scripts/sync-jsapp.js`，支持以下功能：

- 从现有平台导入资源到共享目录
- 验证各平台资源是否与共享目录同步
- 清理平台特定的资源目录

#### 导入现有资源

如果已经有现有的小程序资源或 JS SDK 资源，可以使用同步工具导入：

```bash
# 导入小程序资源 (jsapp)
# 从Android导入
node shared/scripts/sync-jsapp.js import-android-jsapp
# 从Harmony导入
node shared/scripts/sync-jsapp.js import-harmony-jsapp

# 导入SDK资源 (jssdk)
# 从Android导入
node shared/scripts/sync-jsapp.js import-android-jssdk
# 从Harmony导入
node shared/scripts/sync-jsapp.js import-harmony-jssdk
```

#### 验证资源同步状态

验证所有平台的小程序资源和 SDK 资源是否与共享目录同步：

```bash
node shared/scripts/sync-jsapp.js validate
```

#### 清理平台资源目录

清理所有平台的小程序资源和 SDK 资源目录：

```bash
node shared/scripts/sync-jsapp.js clean
```

#### 同步资源

清理平台资源目录并准备从共享目录同步：

```bash
node shared/scripts/sync-jsapp.js sync
```

## 添加新的小程序

要添加新的小程序：

1. 在 `jsapp/` 下创建一个以小程序 appId 命名的新目录
2. 添加 `config.json` 配置文件
3. 添加编译好的小程序包（`.zip` 文件）

示例：
```
shared/jsapp/wx92269e3b2f304afc/
├── config.json
└── wx92269e3b2f304afc.zip
```

## 构建过程

每个平台的构建过程包含将这些共享资源复制到相应位置的脚本：

### Android 平台

在 `android/dimina/build.gradle.kts` 中添加构建任务 `copySharedJsappToAssets`。

### iOS 平台

待补充。

### Harmony 平台

在 `harmony/hvigorfile.ts` 中添加配置阶段完成之后执行的回调函数，实现资源复制功能。

