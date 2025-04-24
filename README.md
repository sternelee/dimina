<div align="center">
<img alt="Dimina" src="https://pt-starimg.didistatic.com/static/starimg/img/0Gd22Gzvni1634047896645.png" width="284" />
</div>

# 星河小程序(Dimina) - 滴滴开源小程序框架
> Dimina 发音是 /diːminə/ ，意为 didi miniprogram 的缩写，致力于打造开源的小程序解决方案。

## 简介

星河小程序是滴滴自研的一套轻量级小程序跨端框架，旨在提供高性能、跨平台、低门槛的开发体验。

星河小程序当前适配了安卓、iOS、鸿蒙三个平台，开发者可以将小程序代码作为独立模块接入当前的 App 或者以小程序语法去开发并打包出一个独立的 APP。

## 演示
| Android | Harmony |
| ---- | ---- |
| ![Android](https://s3-gz01.didistatic.com/packages-mait/img/4UXIfwMOuJ1745485525250.jpg) | ![Harmony](https://s3-gz01.didistatic.com/packages-mait/img/9UeGKg9qdV1745485235803.jpg) |

## 开始使用

## 设计思路

星河小程序对标行业内小程序标准进行实现，将渲染层、逻辑层分离，API 当前对齐了大部分微信小程序进行实现，底层渲染框架使用了 Vue3，并在此基础上实现了一套 Vue 组件。

得益于 Vue 的功能特性和语法相似性，我们的框架本质上是将小程序的语法通过编译器转化成 Vue 的语法，将小程序大部分的特性转换到了 Vue 的实现。

目前已支持的 API/组件/特性 有限，欢迎大家参与共建。

## 已知差异（相比微信小程序）

1. 不支持未声明就使用变量，如视图中使用了 `{{text}}`，但对应 js 的 `data: {}` 未声明就进行调用 `this.setData({text: 'hello'})`
2. 自定义组件的属性如果是布尔值，但传了空字符串，则认为是 [true](https://github.com/vuejs/vue/issues/4710)
3. 避免 :if 和 :for 嵌套在一个元素上同时使用，可能出现访问 item 元素[失败](https://v3-migration.vuejs.org/breaking-changes/v-if-v-for.html#_3-x-syntax)，比如不用在循环根节点直接使用 item 变量，如 `<view wx:for="{{ [1,2,3] }}" wx:if="{{ item===2}}></view>`，要改成 `<view wx:for="{{ [1,2,3] }}" ><block wx:if="{{ item===2}}></block></view>`
4. 同名插槽只能作用一次，比如 `<text slot="info">成功</text><text slot="info">失败</text>`，后面的文案不会显示
5. 同层渲染组件未实现，比如地图/相机。

## License

Dimina 基于 [Apache-2.0](https://opensource.org/license/apache-2-0) 协议进行分发和使用，更多信息参见 [协议文件](LICENSE)。
