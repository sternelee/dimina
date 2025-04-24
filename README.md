<div align="center">
  <img alt="Dimina" src="https://pt-starimg.didistatic.com/static/starimg/img/0Gd22Gzvni1634047896645.png" width="284" />
  <br/>
  <br/>
  <a href="https://github.com/didi/dimina/blob/HEAD/LICENSE">
    <img src="https://img.shields.io/badge/license-Apache%202.0-blue" alt="Dimina is released under the Apache 2.0 license." />
  </a>
  <a href="https://github.com/didi/dimina/blob/HEAD/CONTRIBUTING.md">
    <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs welcome!" />
  </a>
</div>



# 星河小程序(Dimina) - 滴滴开源小程序框架
> Dimina 发音是 /diːminə/ ，意为 didi miniprogram 的缩写，致力于打造开源的小程序解决方案。

## 内容

- [简介](#简介)
- [效果展示](#效果展示)
- [开始使用](#开始使用)
- [设计思路](#设计思路)
- [License](#license)

## 简介

星河小程序是滴滴自研的一套轻量级小程序跨端框架，旨在提供高性能、跨平台、低门槛的开发体验。

星河小程序当前适配了安卓、iOS、鸿蒙、Web四个平台，开发者可以将小程序代码作为独立模块接入当前的 App 或者以小程序语法去开发并打包出一个独立的 APP。

## 效果展示

| Android | Harmony |
| ---- | ---- |
| ![Android](https://s3-gz01.didistatic.com/packages-mait/img/4UXIfwMOuJ1745485525250.jpg) | ![Harmony](https://s3-gz01.didistatic.com/packages-mait/img/9UeGKg9qdV1745485235803.jpg) |

## 开始使用

- [构建小程序](./fe/README.md)
- [Android 接入](./android/README.md)
- [iOS 接入](./iOS/README.md)
- [Harmony 接入](./harmony/README.md)

## 设计思路

星河小程序对标行业内小程序标准进行实现，将渲染层、逻辑层分离，API 当前对齐了大部分微信小程序进行实现，底层渲染框架使用了 Vue3。得益于 Vue 的功能特性和语法相似性，我们的框架本质上是将小程序的语法通过编译器转化成 Vue 的语法，并在此基础上实现了一套小程序标准的 Vue 组件。

目前星河并未完全支持小程序的所有 **API/组件/特性**，当前已支持能力可参考[能力说明文档](./docs/README.md)，支持欢迎大家参与共建。

## License

Dimina 基于 [Apache-2.0](https://opensource.org/license/apache-2-0) 协议进行分发和使用，更多信息参见 [协议文件](LICENSE)。
