# Dimina Harmony SDK

## 介绍
  可以快速将已有的小程序接入到鸿蒙中，支持小程序的启动、跳转、分享、消息推送等能力。

## 系统环境
- HarmonyOS 5.0.0
- compileSdkVersion
  12
- minSdkVersion
  12

## 快速接入

### 步骤1：安装说明
```sh
   ohpm install @didi-dimina/dimina
```

### 步骤2：初始化

在应用的EntryAbility 中初始化DMPApp：

```ts
const dmpConfig: DMPEntryContext = {
  getContext: (): common.UIAbilityContext => {
    return this.context;
  },
  getWindowStage: (): window.WindowStage => {
    return windowStage;
  }
};
DMPApp.init(dmpConfig);
```

###  步骤3：配置路由

在已经存在的Navigation 中绑定routerFactory,业务侧可能自己已经定义了，需要合并一下：

```ts
  Navigation(this.pageInfos) {
        .....
  }
  .navDestination(this.routerFactory)

  @Builder
  routerFactory(name: string, paramMap: Map<string, Object>) {
    if (name == DMPPage.ROUTE_NAME) {
      DMPPage({ uri: name, param: paramMap });
    } else if (name == DMPPhotoPreview.ROUTE_NAME) {
      DMPPhotoPreview({ uri: name, param: paramMap });
    }
  }
```

### 步骤4：引入小程序业务代码

将编译好的小程序压缩包放入 `rawfile/jsapp` 文件夹，文件夹以小程序id命名。每个小程序文件夹需包含以下内容：

1. `config.json` - 小程序配置文件，包含以下字段：

```json5
   {
     "appId": "wx92269e3b2f304afc", // 小程序唯一标识
     "name": "小程序名称",
     "path": "example/index", // 小程序入口路径
     "versionCode": 1, // 启动小程序时会根据版本号确认是否需要更新
     "versionName": "1.0.0"
   }
   ```

2. `[appId].zip` - 小程序代码包，文件名需与appId一致

目录结构示例：

```txt
rawfile/
  └── jsapp/
      ├── wx92269e3b2f304afc/
      │   ├── config.json
      │   └── wx92269e3b2f304afc.zip
      └── wxbaf4b47de04f1d8a/
          ├── config.json
          └── wxbaf4b47de04f1d8a.zip
```

### 步骤5：创建小程序-启动

1. 创建小程序实例

```ts
const appConfig: DMPAppConfig = new DMPAppConfig("小程序名称", "appId")//appId 小程序唯一标识
appConfig.isDebugMode = true
this.app = DMPAppManager.sharedInstance().appWithConfig(appConfig)
```

2. 绑定当前NavPathStack

```ts
this.app.router.init(this.pageInfos)
this.app.startPackageLoader(getContext(this) as common.UIAbilityContext)
```

3. 启动配置

```ts
const launchConfig: DMPLaunchConfig = new DMPLaunchConfig()
launchConfig.openType = DMPOpenType.NavigateTo
this.app.launch(launchConfig)
```

### 调试模式与 vConsole

当 `appConfig.isDebugMode = true`，或当前 HAP 为 debug 包时，SDK 会在加载 pageFrame 时追加 `?vconsole=1`。

JSSDK 直接依赖 vConsole，并随 pageFrame 静态同步打包；只有检测到该启用标记时，pageFrame 才会在 render 初始化前同步初始化 vConsole。
