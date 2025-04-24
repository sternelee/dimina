# 能力说明

## 语法差异

相比微信小程序，具有以下语法和实现差异：

1. 不支持未声明就使用变量，如视图中使用了 `{{text}}`，但对应 js 的 `data: {}` 未声明就进行调用 `this.setData({text: 'hello'})`
2. 自定义组件的属性如果是布尔值，但传了空字符串，则认为是 [true](https://github.com/vuejs/vue/issues/4710)
3. 避免 :if 和 :for 嵌套在一个元素上同时使用，可能出现访问 item 元素[失败](https://v3-migration.vuejs.org/breaking-changes/v-if-v-for.html#_3-x-syntax)，比如不用在循环根节点直接使用 item 变量，如 `<view wx:for="{{ [1,2,3] }}" wx:if="{{ item===2}}></view>`，要改成 `<view wx:for="{{ [1,2,3] }}" ><block wx:if="{{ item===2}}></block></view>`
4. 同名插槽只能作用一次，比如 `<text slot="info">成功</text><text slot="info">失败</text>`，后面的文案不会显示

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

* 同层渲染组件当前都未支持。

## API 列表

| 分类              | API 名称                          | Android | iOS | Harmony |
|-------------------|----------------------------------|---------|-----|---------|
| 基础              | env                              | ✓       | □   | ✓       |
|                   | canIUse                          | ✓       | □   | ✓       |
| 基础 - 系统        | openSystemBluetoothSetting       | ✓       | -   | -       |
|                   | getWindowInfo                    | ✓       | □   | ✓       |
|                   | getSystemSetting                 | ✓       | □   | ✓       |
|                   | getSystemInfoSync                | ✓       | □   | ✓       |
|                   | getSystemInfoAsync               | ✓       | □   | ✓       |
|                   | getSystemInfo                    | ✓       | □   | ✓       |
| 路由               | reLaunch                         | ✓       | □   | ✓       |
|                   | redirectTo                       | ✓       | □   | ✓       |
|                   | navigateTo                       | ✓       | □   | ✓       |
|                   | navigateBack                     | ✓       | □   | ✓       |
| 界面 - 交互        | showToast                        | ✓       | □   | ✓       |
|                   | showModal                        | ✓       | □   | ✓       |
|                   | showLoading                      | ✓       | □   | ✓       |
|                   | showActionSheet                  | ✓       | □   | ✓       |
|                   | hideToast                        | ✓       | □   | -       |
|                   | hideLoading                      | ✓       | □   | ✓       |
| 界面 - 导航栏       | setNavigationBarTitle            | ✓       | □   | ✓       |
|                   | setNavigationBarColor            | ✓       | □   | ✓       |
| 界面 - 滚动        | pageScrollTo                     | ✓       | □   | ✓       |
| 界面 - 菜单        | getMenuButtonBoundingClientRect  | ✓       | □   | ✓       |
| 网络               | request                          | ✓       | □   | ✓       |
|                   | downloadFile                     | ✓       | □   | ✓       |
|                   | uploadFile                       | ✓       | □   | ✓       |
| 数据缓存           | setStorageSync                   | ✓       | □   | ✓       |
|                   | getStorageSync                   | ✓       | □   | ✓       |
|                   | removeStorageSync                | ✓       | □   | ✓       |
|                   | clearStorageSync                 | ✓       | □   | ✓       |
|                   | setStorage                       | ✓       | □   | ✓       |
|                   | getStorage                       | ✓       | □   | ✓       |
|                   | removeStorage                    | ✓       | □   | ✓       |
|                   | clearStorage                     | ✓       | □   | ✓       |
|                   | getStorageInfoSync               | ✓       | □   | ✓       |
|                   | getStorageInfo                   | ✓       | □   | ✓       |
| 媒体 - 图片        | saveImageToPhotosAlbum           | ✓       | □   | ✓       |
|                   | previewImage                     | ✓       | □   | ✓       |
|                   | compressImage                    | ✓       | □   | ✓       |
|                   | chooseImage                      | ✓       | □   | ✓       |
| 媒体 - 视频        | chooseMedia                      | ✓       | □   | ✓       |
| 设备 - 联系人       | chooseContact                    | ✓       | □   | ✓       |
|                   | addPhoneContact                  | ✓       | □   | ✓       |
| 设备 - 剪贴板       | setClipboardData                 | ✓       | □   | ✓       |
|                   | getClipboardData                 | ✓       | □   | ✓       |
| 设备 - 震动        | vibrateShort                     | ✓       | □   | ✓       |
|                   | vibrateLong                      | ✓       | □   | ✓       |
| 设备 - 键盘        | hideKeyboard                     | ✓       | □   | ✓       |
| 设备 - 网络        | getNetworkType                   | ✓       | □   | ✓       |
| 设备 - 电话        | makePhoneCall                    | ✓       | □   | ✓       |

说明：

* "✓" 表示支持该平台。
* "□" 表示不支持。
* "-" 表示明确不支持该平台。
