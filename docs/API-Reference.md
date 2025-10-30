# Dimina 能力参考指南

## 语法差异

Vue 作为底层的渲染框架，自然会与小程序的语法存在一定的差异。这些差异点需要我们在框架中进行适配，或者要求业务代码做些许的改造，以实现无缝迁移。例如：

相比微信小程序，具有以下语法和实现差异：

- **Data 字段的声明**

    小程序的 `data` 字段可以不提前声明直接使用，而 Vue 则需要显式声明。这种差异导致业务代码需要额外的字段初始化。比如视图中使用了 `{{text}}`，但对应 js 的 `data: {}` 未声明就进行调用 `this.setData({text: 'hello'})`

- **具名插槽的显示逻辑**

    在小程序中，具名插槽可以同名且能同时渲染显示，而 Vue 的插槽机制会默认覆盖同名插槽。对此，需要为小程序的插槽机制设计一套适配逻辑。比如 `<text slot="info">成功</text><text slot="info">失败</text>`，后面的文案不会显示。

- **组件属性的默认值**

    小程序中，组件属性如果为空字符串，会默认解析为 `false`；而在 Vue 中，空字符串会被解析为 [`true`](https://github.com/vuejs/vue/issues/4710)。这种行为差异需要在属性处理逻辑中进行适配。
    另外针对字符串类型的组件属性，如果未赋值，微信小程序会处理成空字符串（伴有提示：`received type-uncompatible value: expected <String> but get null value. Use empty string instead.`），但是星河不会处理而是直接透传，这一点请注意。

- **循环内的访问限制**

    在小程序中，`wx:for` 标签用于在元素上直接进行循环操作，并允许直接在该元素上使用 `wx:if` 直接访问循环实例的属性。Vue 的 `v-for` 不支持这个特性，需要修改访问属性的方法移动到下一级节点。

## 组件列表

| 组件              |
|-------------------|
| block             |
| button            |
| checkbox          |
| checkbox-group    |
| cover-image       |
| cover-view        |
| form              |
| icon              |
| image             |
| input             |
| label             |
| moveable-area     |
| moveable-view     |
| navigation-bar    |
| navigator         |
| picker-view       |
| picker-view-column|
| progress          |
| radio             |
| radio-group       |
| rich-text         |
| scroll-view       |
| slider            |
| swiper            |
| swiper-item       |
| switch            |
| text              |
| textarea          |
| view              |

说明：

- 同层渲染组件暂未支持(Android/iOS)。
- tabBar 暂未支持(Android/iOS/Harmony)。

## API 列表

| 分类              | API 名称                          | Android | iOS | Harmony | Web |
|-------------------|----------------------------------|---------|-----|---------|-----|
| 基础              | env                              | ✓       | ✓   | ✓       | ✓   |
|                   | canIUse                          | ✓       | ✓   | ✓       | ✗  |
| 基础 - 系统        | openSystemBluetoothSetting       | ✓       | ✗   | ✗       | ✗   |
|                   | getWindowInfo                    | ✓       | ✓   | ✓       | ✗  |
|                   | getSystemSetting                 | ✓       | ✓   | ✓       | ✗   |
|                   | getSystemInfoSync                | ✓       | ✓   | ✓       | ✗   |
|                   | getSystemInfoAsync               | ✓       | ✓   | ✓       | ✓   |
|                   | getSystemInfo                    | ✓       | ✓   | ✓       | ✗  |
| 路由               | reLaunch                         | ✓       | ✓   | ✓       | ✓   |
|                   | redirectTo                       | ✓       | ✓   | ✓       | ✓   |
|                   | navigateTo                       | ✓       | ✓   | ✓       | ✓   |
|                   | navigateBack                     | ✓       | ✓   | ✓       | ✓   |
| 界面 - 交互        | showToast                        | ✓       | ✓   | ✓       | ✓   |
|                   | showModal                        | ✓       | ✓   | ✓       | ✓   |
|                   | showLoading                      | ✓       | ✓   | ✓       | ✓   |
|                   | showActionSheet                  | ✓       | ✓   | ✓       | ✓   |
|                   | hideToast                        | ✓       | ✓   | □       | ✓  |
|                   | hideLoading                      | ✓       | ✓   | ✓       | ✓   |
| 界面 - 导航栏       | setNavigationBarTitle            | ✓       | ✓   | ✓       | ✓   |
|                   | setNavigationBarColor            | ✓       | ✓   | ✓       | ✓   |
| 界面 - 滚动        | pageScrollTo                     | ✓       | ✓   | ✓       | ✓   |
| 界面 - 菜单        | getMenuButtonBoundingClientRect  | ✓       | ✓   | ✓       | ✓  |
| 网络               | request                          | ✓       | ✓   | ✓       | ✓   |
|                   | downloadFile                     | ✓       | ✓   | ✓       | ✗   |
|                   | uploadFile                       | ✓       | ✓   | ✓       | ✗   |
| 数据缓存           | setStorageSync                   | ✓       | ✓   | ✓       | ✗  |
|                   | getStorageSync                   | ✓       | ✓   | ✓       | ✗   |
|                   | removeStorageSync                | ✓       | ✓   | ✓       | ✗   |
|                   | clearStorageSync                 | ✓       | ✓   | ✓       | ✗   |
|                   | setStorage                       | ✓       | ✓   | ✓       | ✓   |
|                   | getStorage                       | ✓       | ✓   | ✓       | ✓   |
|                   | removeStorage                    | ✓       | ✓   | ✓       | ✓   |
|                   | clearStorage                     | ✓       | ✓   | ✓       | ✓   |
|                   | getStorageInfoSync               | ✓       | ✓   | ✓       | ✗   |
|                   | getStorageInfo                   | ✓       | ✓   | ✓       | ✓   |
| 媒体 - 图片        | saveImageToPhotosAlbum           | ✓       | ✓   | ✓       | ✗   |
|                   | previewImage                     | ✓       | ✓   | ✓       | □   |
|                   | compressImage                    | ✓       | ✓   | ✓       | ✗   |
|                   | chooseImage                      | ✓       | ✓   | ✓       | ✗   |
| 媒体 - 视频        | chooseMedia                      | ✓       | ✓   | ✓       | ✗   |
| 设备 - 联系人       | chooseContact                    | ✓       | ✓   | ✓       | ✗   |
|                   | addPhoneContact                  | ✓       | ✓   | ✓       | ✗   |
| 设备 - 剪贴板       | setClipboardData                 | ✓       | ✓   | ✓       | ✓   |
|                   | getClipboardData                 | ✓       | ✓   | ✓       | ✓   |
| 设备 - 震动        | vibrateShort                     | ✓       | ✓   | ✓       | ✗   |
|                   | vibrateLong                      | ✓       | ✓   | ✓       | ✗   |
| 设备 - 键盘        | hideKeyboard                     | ✓       | ✓   | ✓       | ✗   |
| 设备 - 网络        | getNetworkType                   | ✓       | ✓   | ✓       | ✓   |
| 设备 - 电话        | makePhoneCall                    | ✓       | ✓   | ✓       | ✗   |

说明：

- "✓" 表示支持该平台。
- "□" 表示当前不支持。
- "✗" 表示明确不支持该平台。
