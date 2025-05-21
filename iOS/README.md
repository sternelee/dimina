# Dimina iOS SDK

## 系统要求

- iOS 14.0+
- Swift 5.0+
- Xcode 14.0+

## 快速接入

### 步骤 1: 添加 SDK 到项目

您可以通过以下方式将 Dimina SDK 添加到您的 iOS 项目中：

#### CocoaPods

在您的 `Podfile` 中添加：

```ruby
pod 'Dimina', :git => 'https://github.com/didi/dimina.git'
```

然后运行：

```bash
pod install
```

### 步骤 2: 准备小程序资源

将编译好的小程序压缩包放入 `JsApp.bundle` 文件夹，文件夹以小程序id命名。每个小程序文件夹需包含以下内容：

1. `config.json` - 小程序配置文件，包含以下字段：

```json
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
JsApp.bundle/
  ├── wx92269e3b2f304afc/
  │   ├── config.json
  │   └── wx92269e3b2f304afc.zip
  └── wxbaf4b47de04f1d8a/
      ├── config.json
      └── wxbaf4b47de04f1d8a.zip
```

### 步骤 3: 启动小程序

```swift
import Dimina
import SwiftUI

struct ContentView: View {
    var body: some View {
        Button("启动小程序") {
            launchMiniProgram()
        }
    }

    func launchMiniProgram() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        {
            let navController = UINavigationController()

            // 创建一个新的 ContentView 作为根视图，可以自行替换
            let contentView = ContentView()
            let hostingController = UIHostingController(rootView: contentView)
            
            hostingController.navigationItem.title = "星河小程序"

            // 设置为根视图
            navController.viewControllers = [hostingController]
            window.rootViewController = navController

            // 创建小程序配置和实例
            let manager: DMPAppManager = DMPAppManager.sharedInstance()
            let appConfig: DMPAppConfig = DMPAppConfig(appName: "小程序名称", appId: "wx92269e3b2f304afc")
            let app: DMPApp = manager.appWithConfig(appConfig: appConfig)

            // 设置导航
            app.getNavigator()!.setup(navigationController: navController)

            // 启动小程序
            Task { @MainActor in
                let launchConfig: DMPLaunchConfig = DMPLaunchConfig()
                await app.launch(launchConfig: launchConfig)
            }
        }
    }
}
```


### 关闭小程序

当不再需要小程序时，可以关闭它：

```swift
app.destroy()
```

## 权限处理

小程序可能需要访问设备的各种权限，如相机、位置等。请确保在 Info.plist 中添加相应的权限描述：

```xml
<key>NSCameraUsageDescription</key>
<string>小程序需要使用您的相机</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>小程序需要使用您的位置信息</string>
```


## 示例项目

运行命令：
```bash
cd iOS && pod install
```

使用 Xcode 打开 dimina.xcworkspace 可以查看示例项目。