# Android 原生组件承载后端

`NativeComponentBackend` 将原生 View 的承载方式从组件实现中抽出。地图、视频、cover-view、cover-image 和内嵌 web-view 共用同一个页面后端。地图服务商通过 `MapProvider` 扩展，承载方式通过 `NativeComponentBackendFactory` 扩展，两者独立。

## 职责与调用链

```text
Render 的组件消息 / 布局 / 触摸
  → NativeComponentHost
      → 组件实例 / MapProvider：SDK 属性、命令、事件、生命周期
      → NativeComponentBackend：挂载、布局、裁剪、层级、触摸、移除
```

| 接口 | 约定 |
| --- | --- |
| `attach(id, type, view, onVisibilityChanged)` | 接收尚无 parent 的 View；同一后端内 id 唯一；布局可见性改变时通知组件 |
| `updateLayout(id, layout)` | 接收不可变的 CSS 坐标快照，由后端转换和应用 |
| `dispatchTouch(message)` | 处理 Render 转发的多指触摸；无需转发的后端可返回 false |
| `updatePageBackgroundColor(color)` | 更新页面底色；有原生组件展示时不能用不透明 WebView 盖住组件 |
| `detach(id)` | 先取消尚未结束的手势，再移除自己承载的 View |
| `destroy()` | 幂等清理本页面的挂载和监听；此后不再接收新组件 |

后端不销毁 SDK 实例。Host 在后端移除视图之后调用组件 `release`，地图再调用 provider 的 `destroy`。地图根据后端可见性和 Activity 前后台状态决定 `resume/pause`。其他组件保留各自原有的播放和生命周期语义。

所有接口和注册操作在主线程调用。每个页面创建独立后端，不共享 id、触摸状态或视图。旧页面的后端被清理后不能复用；新页面由工厂重新创建。布局、挂载和命令仍通过现有 NativeComponentHost 路径发送。

## 默认实现与扩展

默认使用 `WebViewUnderlayBackend`，无需增加初始化代码。现有 `NativeComponentHost(activity, webView, overlay) { message -> … }` 构造方式保留，由它调用工厂；也可以通过接受 `NativeComponentBackend` 的构造方法显式注入。

宿主在打开小程序前注册工厂。例如，下面使用现有实现并显式配置 WebView 恢复时的页面底色：

```kotlin
import android.graphics.Color
import com.didi.dimina.ui.view.nativecomponent.NativeComponentBackends
import com.didi.dimina.ui.view.nativecomponent.WebViewUnderlayBackend

NativeComponentBackends.setFactory { context ->
    WebViewUnderlayBackend(
        webView = context.webView,
        layer = context.nativeLayer,
        pageBackgroundColor = Color.WHITE,
    )
}

// 恢复默认工厂；已有页面继续使用原后端。
NativeComponentBackends.resetFactory()
```

自定义实现替换工厂返回值即可。工厂必须每次返回新实例。`context` 提供当前 Activity、WebView 和原生组件层；默认后端要求原生层与 WebView 的位置和尺寸对齐，并位于 WebView 下方，现有容器已满足此约定。

默认后端初始底色为白色，DiminaActivity 在创建 Host 时传入页面配置颜色，运行时背景 API 也通过 Host 更新后端。原生组件展示期间保持 WebView 透明，移除后恢复最新配置色。WebView 的页面底色独立于 `View.background`，不能通过读取 background 推断；自定义容器应显式传入 `pageBackgroundColor` 或调用更新接口。普通 background drawable 另外保存和恢复。

## 能力边界

默认后端的 `capabilities`：

| 字段 | 值 | 含义 |
| --- | --- | --- |
| `name` | `webview-underlay` | 系统 WebView 下方承载原生层 |
| `requiresTransparentDomAncestors` | true | 原生组件及其 DOM 祖先需要透明背景 |
| `requiresDomTouchForwarding` | true | 使用现有 DOM 命中与触摸转发 |
| `embedsIntoDom` | false | 未接入浏览器的 DOM 合成层 |
| `supportsPageBackground` | true | 接收根页面纯色背景，由原生底层绘制 |

地图挂载成功时通过 `nativeComponentBackend.supportsPageBackground` 协商页面底色承载。只有明确支持的后端才启用根页面纯色转移；其他能力仍供原生宿主查询，注册后端不会自动改变 embed 和触摸协议。

默认后端保留现有兼容行为：同步页面滚动和尺寸变化；将 CSS 坐标转换为原生像素；用 `clipBounds` 裁剪且保留完整 View 尺寸；地图位于原生 cover 组件下方；隐藏或卸载时取消手势；最后一个可见组件移除后恢复 WebView 底色。清理只移除本后端挂载的 View，不清空宿主原生层中的其他子视图。

这次抽象覆盖 Android，未改变 iOS/Harmony 的承载实现。它也没有消除系统 WebView 下方承载方案的限制：不支持任意 CSS stacking context、复杂 mask、旋转/斜切变换等完整 DOM 合成。地图 SDK 仍需提供适合承载的视图；当前高德使用 TextureMapView。

后续接入有原生 embed 能力的 WebView 内核时，可以在此边界实现新的后端，但还需要对应内核、Render 节点关联、布局/触摸协议以及 SDK 渲染适配。仅替换这个工厂不会获得完整同层渲染。

源码入口：[`NativeComponentBackend.kt`](../android/dimina/src/main/kotlin/com/didi/dimina/ui/view/nativecomponent/NativeComponentBackend.kt)、[`NativeComponentLayout.kt`](../android/dimina/src/main/kotlin/com/didi/dimina/ui/view/nativecomponent/NativeComponentLayout.kt)、[`WebViewUnderlayBackend.kt`](../android/dimina/src/main/kotlin/com/didi/dimina/ui/view/nativecomponent/WebViewUnderlayBackend.kt)。地图 SDK 扩展见[地图接入](./Map-Integration.md)。

## 本地验证（2026-09-08）

Android 核心 316 项单元测试、可选高德模块构建、3 项后端模拟器测试和 6 项前端原生协议回归通过。模拟器测试使用普通原生 View 与真实系统 WebView，检查窗口合成像素、HTML 覆盖、裁剪尺寸、动态底色、手势取消、页面隔离和清理。手势取消和底色恢复分别完成隔离消融，禁用后对应断言失败，恢复后通过。

这些测试未加载地图 SDK 的真实底图，不能证明 TextureMapView GPU、不同厂商设备或 WebView 版本的表现；各组件的完整业务生命周期、实际视频播放和高德地图仍需真机验收。

### Android 页面底色与分包地图回归

官方分包示例的 `page { background-color: #F8F8F8 }` 会遮住 WebView 下方的原生地图。Render 在后端明确支持时，采集 `html/body` 的纯色背景并随布局传递 `pageBackgroundColors`，使用独立样式规则临时使这两个根节点透明；后端将颜色按顺序合成在配置底色之上，在原生组件层绘制。示例源码和原有内联样式不改动。多个地图共享页面规则，最后一个销毁时撤销；隐藏地图期间保留底色，根节点 class/style 变化随布局更新重新采样。

这项兼容只处理根页面纯色。根背景图片/渐变、无法解析的颜色和优先级更高的内联 `!important` 保留原样；嵌套容器的不透明背景仍需要透明祖先或更完整的合成后端。不能据此宣称支持任意 CSS 同层渲染。

验证：Components 267 项、Android 核心 316 项、4 项模拟器真实 WebView 合成测试通过。隔离消融分别禁用 DOM 透明规则和原生底色合成，前者 3 项断言失败，后者在地图外区域像素断言失败；恢复后通过。真机已确认原分包底图显示且页面底色保留。

### 页面背景更新的性能优化

背景采样按 Document 共享缓存，滚动和地图位置变化直接复用结果，不再反复移除/写回样式规则。根节点属性、head 中样式表增删/内容变更、外链样式加载、窗口 resize 和系统深浅色变化会使缓存失效，并通知同页面地图更新。同步读取先消费尚未投递的 MutationObserver 记录，避免属性刚改变时读到旧缓存；自身兼容样式的变更不会触发循环。最后一个地图释放时清理观察者、主题监听和透明规则。直接 CSSOM 修改规则、持续 CSS 背景动画不在本次验证范围。

Android 后端缓存背景输入与合成色：相同输入不重复合成，相同最终颜色不重新创建或设置 ColorDrawable；最后一个背景承载节点移除后恢复原背景对象并清空缓存。

在真机系统 WebView 的隔离文档中，对相同的双地图、300 次布局背景读取进行对比：初始化后的额外 getComputedStyle 调用从 2400 次降为 0 次；本次测量总耗时约 50.4 ms → 0.4 ms。该结果只衡量背景采样函数，不代表整页帧率、CPU 或功耗提升比例。

验证：Components 272 项、Android 核心 316 项通过，5 项真实 WebView/原生层设备回归通过，其中连续 300 次布局更新复用同一背景对象，并检查配置底色变化、隐藏、销毁与重建。隔离消融分别禁用前端缓存、根属性失效机制、原生背景缓存，出现额外样式读取、漏掉换色通知、背景对象被替换的预期断言失败；全部恢复后通过。

最终调试包已安装到 Android 真机。原分包地图显示正常；在实际地图 WebView 连续触发 30 帧 scroll 布局同步，背景样式规则写入为 0 次。临时修改 body 底色后原生背景正确换色、地图继续显示；恢复样式并返回列表后底色恢复，重进地图中心仍为广州示例坐标。临时样式和调试转发已清理。
