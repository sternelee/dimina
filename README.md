<div align="center">

![Dimina](./static/logo.png)

[![Dimina is released under the Apache 2.0 license.](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/didi/dimina/blob/HEAD/LICENSE)
[![Platform](https://img.shields.io/badge/Platform-%20Android%20%7C%20iOS%20%7C%20Harmony%20%7C%20Web-brightgreen.svg)](#效果展示)
[![PRs welcome!](https://img.shields.io/badge/PRs-Welcome-orange.svg)](https://github.com/didi/dimina/blob/HEAD/CONTRIBUTING.md)

</div>

# 星河小程序(Dimina) - 滴滴开源小程序框架

> Dimina 发音是 /diːminə/ ，意为 didi miniprogram 的缩写，致力于打造灵活、轻巧的小程序跨端框架。

## 概览

- [简介](#简介)
- [设计思路](#设计思路)
- [效果展示](#效果展示)
- [上手使用](#上手使用)
- [开源协议](#开源协议)

## 简介

星河小程序（以下统称为 `Dimina` ），是滴滴自研的一套轻量级小程序跨端框架，旨在提供高性能、跨平台、低门槛的开发体验。

Dimina 当前已经适配了 Android、iOS、Harmony、Web 四个平台，开发者可将 Dimina 作为**移动端跨平台框架**进行使用，将已有小程序代码编写的逻辑作为独立模块接入当前的 App 或者采用小程序语法去开发需求并打包出一个独立的原生 APP。

## 效果展示

| Android | iOS | Harmony |
| ---- | ---- | ---- |
| ![Android](./static/android.jpg) | ![iOS](./static/ios.jpg) | ![Harmony](./static/harmony.jpg) |

## 上手使用

- [小程序打包说明](./fe/packages/compiler/README.md)
- [Android 接入说明](./android/README.md)
- [iOS 接入说明](./iOS/README.md)
- [Harmony 接入说明](./harmony/dimina/README.md)

## 参与共建

Dimina 遵循[小程序标准化白皮书](https://www.w3.org/TR/mini-app-white-paper/)进行设计，API 当前对齐了大部分微信小程序实现，底层视图渲染框架使用了 Vue3。

得益于 Vue 丰富的功能特性，星河框架中的渲染层本质上是将小程序的语法通过编译器转化成 Vue 的语法，并在此基础上实现了一套小程序标准的 Vue 组件。再把视图页面通过各大移动端系统的小程序容器进行加载展示。

至于逻辑层和消息通道的交互部分，更多底层和实现细节可参考[说明文档](./docs/README.md)。

由于行业内个各大厂的小程序方案已迭代多年，目前星河并未完全支持小程序的所有 **API/组件/特性**。当前我们已支持的能力可参考[API说明](./docs/API-Reference.md)，欢迎大家 **Star、Fork、贡献代码与建议**。

## 开源协议

Dimina 基于 [Apache-2.0](https://opensource.org/license/apache-2-0) 协议进行分发和使用，更多信息参见[协议文件](LICENSE)。
