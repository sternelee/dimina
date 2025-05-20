<p align="right">
  <a href="./README_EN.md">
    <img src="https://img.shields.io/badge/README-English%20⤴-26A69A.svg" alt="English Version" />
  </a>
</p>

<div align="center">

![Dimina](./static/logo.png)

[![Dimina is released under the Apache 2.0 license.](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/didi/dimina/blob/HEAD/LICENSE)
[![Platform](https://img.shields.io/badge/Platform-%20Android%20%7C%20iOS%20%7C%20Harmony%20%7C%20Web-4CAF50)](#效果展示)
[![PRs welcome!](https://img.shields.io/badge/PRs-Welcome-FF6F61)](https://github.com/didi/dimina/blob/HEAD/CONTRIBUTING.md)

# 星河小程序（Dimina）——滴滴开源跨端小程序框架

> Dimina 发音为 /diːminə/，是 didi miniprogram 的缩写，旨在打造灵活、轻量的小程序跨端开发框架。

[简介](#简介) • [效果展示](#效果展示) • [上手使用](#上手使用) • [参与共建](#参与共建) • [星标趋势](#星标趋势) • [开源协议](#开源协议)

</div>

## 简介

星河小程序（以下简称 `Dimina`）是滴滴自研的一套轻量级跨端小程序框架，致力于为开发者提供高性能、跨平台、低门槛的开发体验。

目前，Dimina 已支持 Android、iOS、Harmony 和 Web 四大平台。开发者可以将 Dimina 作为**移动端跨平台开发框架**，将已有小程序逻辑以独立模块方式集成到现有 App，或直接采用小程序语法进行开发，并一键打包生成独立原生 App。

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

Dimina 遵循[小程序标准化白皮书](https://www.w3.org/TR/mini-app-white-paper/)进行设计，目前已对齐微信小程序的主要功能。

已支持能力详见[Dimina 能力参考指南](./docs/API-Reference.md)。

得益于 Vue3 与小程序语法的高度相似，Dimina 底层视图渲染框架选择基于 Vue 构建。 Dimina 框架通过[DMCC](./fe/packages/compiler/README.md)将小程序语法转译为 Vue 语法，并在此基础上实现了完整的小程序标准 Vue 组件体系。最终，通过实现端侧小程序容器来提供原生能力，同时灵活加载并展示视图页面。

如需了解更多关于编译器原理、框架底层实现以及逻辑层与消息通道的交互机制，欢迎查阅[详细文档](./docs/README.md)。

由于行业内各类小程序方案已迭代多年，Dimina 目前尚未完全覆盖全部小程序 **API/组件/特性**。欢迎大家积极贡献代码、提出建议，与我们共同完善 Dimina。

## 星标趋势

如果你觉得 Dimina 对你有帮助，欢迎点击右上角 ⭐Star 支持我们，让更多人了解和使用这个项目。

<img src="https://api.star-history.com/svg?repos=didi/dimina&type=Date" style="width: 60%; height: auto;">

## 开源协议

Dimina 遵循 [Apache-2.0](https://opensource.org/license/apache-2-0) 协议进行分发和使用，更多详情请参见[协议文件](LICENSE)。
