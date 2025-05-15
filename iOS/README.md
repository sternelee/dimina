# Dimina iOS SDK

## 系统要求

- iOS 13.0+
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

#### Swift Package Manager

在 Xcode 中，选择 `File > Add Packages...`，然后输入以下 URL：

```
https://github.com/didi/dimina.git
```

### 步骤 2: 初始化 SDK

在应用的 `AppDelegate` 或 `SceneDelegate` 中初始化 Dimina SDK：

```swift
import DiminaKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 初始化 Dimina SDK
        DMPResourceManager.prepareSdk()
        
        return true
    }
}
```

### 步骤 3: 准备小程序资源

将编译好的小程序压缩包放入 `JSAppBundle.bundle` 文件夹，文件夹以小程序id命名。每个小程序文件夹需包含以下内容：

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
JSAppBundle.bundle/
  ├── wx92269e3b2f304afc/
  │   ├── config.json
  │   └── wx92269e3b2f304afc.zip
  └── wxbaf4b47de04f1d8a/
      ├── config.json
      └── wxbaf4b47de04f1d8a.zip
```

### 步骤 4: 启动小程序

```swift
import DiminaKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        Button("启动小程序") {
            launchMiniProgram()
        }
    }
    
    func launchMiniProgram() {
        // 创建小程序配置
        let appConfig = DMPAppConfig(appName: "小程序名称", appId: "wx92269e3b2f304afc")
        
        // 获取小程序实例
        let app = DMPAppManager.sharedInstance().appWithConfig(appConfig: appConfig)
        
        // 准备小程序资源
        DMPResourceManager.prepareApp(appId: appConfig.appId)
        
        // 创建启动配置
        let launchConfig = DMPLaunchConfig()
        launchConfig.openType = .navigateTo
        
        // 启动小程序
        Task {
            await app.launch(launchConfig: launchConfig)
        }
    }
}
```

## 高级配置

### 自定义导航

您可以通过 `DMPNavigator` 类来自定义小程序的导航行为：

```swift
// 获取导航器
let navigator = app.getNavigator()

// 导航到指定页面
navigator?.launch(to: "pages/index/index", query: ["key": "value"])
```

### 生命周期管理

当不再需要小程序时，应该销毁它以释放资源：

```swift
// 销毁小程序
app.destroy()
```
