# 小程序多实例与后台留存

不同 appId 可以同时保留运行状态；同一个 appId 从宿主入口再次打开时复用已有实例，恢复当前页面栈，不重新执行 `App.onLaunch`、`Page.onLoad`。

## 关闭界面与销毁实例

点击原生胶囊或菜单的关闭按钮，会隐藏界面并保留 JS 运行时和页面。Web 的 `closeApp` 同样保留实例。隐藏时派发页面和应用的隐藏生命周期，恢复时派发显示生命周期；隐藏不会触发页面卸载。

宿主主动销毁、重新进入、应用更新和卸载继续使用原来的清理流程。小程序自身的 `exitMiniProgram`、`navigateBackMiniProgram` 等显式路由 API 保持现有契约。

| 平台 | 隐藏并保留 | 再次打开 | 主动销毁 |
| --- | --- | --- | --- |
| Android | `Dimina.hideMiniProgram(appId)` | `startMiniProgram(activity, miniProgram)` | `Dimina.closeMiniProgram(appId)` |
| iOS | `try await app.hideMiniProgram()` | `appWithConfig` 取得实例，设置导航控制器后 `await app.launch(...)` | `try await app.closeMiniProgram()` |
| Harmony | `await app.hideMiniProgram()` | `appWithConfig` 取得实例后 `startDimina(...)` | `await app.closeMiniProgram()` |
| Web | `container.closeApp(app)` | `container.openApp({ appId })` | `container.application.destroyRootView(app)` |

Web 基础示例列表打开小程序时不再传入 `destroy: true`。宿主仍可显式传入该选项，在打开新小程序时释放其他实例。

## 各平台如何保留页面

- Android：每个小程序入口使用独立的 Activity 任务栈。重新打开时将原任务移到前台，保留子页面和已加载的 Tab；普通页面导航仍在同一任务内进行。关闭界面返回调用方任务，小程序任务可出现在系统最近任务列表中。不会使用 `CLEAR_TOP` 截断原页面栈。
- iOS：导航器保留原页面控制器及其 WebView，隐藏时将它们从宿主导航栈摘除。恢复时重新挂载原控制器，销毁时释放保存的页面。
- Harmony：隐藏时只移除原生路由入口，保留页面记录、Web 节点、JS Worker 和 TabBar 状态。恢复时根据原记录重建路由壳，继续使用原 Web 节点。键盘和事件订阅跟随界面解绑，TabBar 消息按 appIndex 隔离。
- Web：继续使用容器私有的 appId 实例登记表，保留逻辑 Worker、页面 bridge 与 iframe。

Android、iOS 和 Harmony 的后台实例不能操作前台导航栈。销毁后台实例只释放自己的资源，不弹出其他小程序或宿主的页面。

## 生命周期与资源边界

留存状态属于当前宿主进程，不是磁盘快照。宿主进程被系统终止、Android 后台 Activity 被回收或实例被显式销毁后，下一次打开走冷启动。后台留存不申请操作系统后台执行权限，也不保证宿主切到系统后台后定时器或网络任务继续执行。

每个保留实例仍占用 JS 和 WebView 内存，宿主可通过主动销毁入口释放不再需要的实例。Harmony 隐藏期间的 TabBar 更新在恢复时应用；待处理更新最多 128 条，超过上限会失败，避免无限积压。

Harmony 的 `customLaunchPageCallBack` 自定义挂载页面没有框架路由入口，由宿主负责隐藏和恢复，不适用默认路由隐藏方法。

## 验证

1. 打开小程序 A，进入二级页面并修改页面状态。
2. 点击胶囊关闭，打开小程序 B，再关闭 B。
3. 再次打开 A：应恢复原二级页面及状态，不重新执行启动和页面加载生命周期。
4. 在二级页面返回：应回到 A 的上一级；Android、Harmony 的栈底系统返回应隐藏小程序。
5. 对后台 A 调用宿主关闭接口：B 的前台界面不应变化，再次打开 A 应冷启动。
6. TabBar 场景重复上述操作，检查选中项、已加载 Tab、徽标及页面状态。

回归入口：

- Android：`:dimina:testDebugUnitTest`，以及示例应用中的任务栈切换。
- iOS：`DMPRetainedMiniProgramTests` 和 `DMPNavigatorCapsuleTests`。
- Web：`retained-mini-program.spec.ts` 与容器 SDK 现有生命周期、并发打开测试。
- Harmony：安装前端依赖后执行 `node --test harmony/scripts/retained-pages.test.mjs`；ArkUI 编译通过 `dimina:assembleHar` 验证，实际界面复用仍需设备验证。
