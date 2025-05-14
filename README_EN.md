<p align="right">
  <a href="./README.md">
    <img src="https://img.shields.io/badge/README-中文版%20⤴-4B8CFF.svg" alt="中文版" />
  </a>
</p>

<div align="center">

![Dimina](./static/logo.png)

[![Dimina is released under the Apache 2.0 license.](https://img.shields.io/badge/License-Apache%202.0-26A69A)](https://github.com/didi/dimina/blob/HEAD/LICENSE)
[![Platform](https://img.shields.io/badge/Platform-%20Android%20%7C%20iOS%20%7C%20Harmony%20%7C%20Web-4CAF50)](#showcase)
[![PRs welcome!](https://img.shields.io/badge/PRs-Welcome-FF6F61)](https://github.com/didi/dimina/blob/HEAD/CONTRIBUTING.md)

</div>

# Dimina - Didi's Open Source Cross-Platform Mini Program Framework

> Dimina is pronounced /diːminə/, short for didi miniprogram. It is designed to provide a flexible and lightweight cross-platform mini program framework.

## Overview

- [Introduction](#introduction)
- [Showcase](#showcase)
- [Getting Started](#getting-started)
- [Contributing](#contributing)
- [Star Trend](#star-trend)
- [License](#license)

## Introduction

Dimina is a lightweight cross-platform mini program framework independently developed by Didi. It aims to offer developers a high-performance, cross-platform, and low-barrier development experience.

Currently, Dimina supports four major platforms: Android, iOS, Harmony, and Web. Developers can use Dimina as a **mobile cross-platform framework**—either integrating existing mini program logic as independent modules into current apps, or developing new features using mini program syntax and packaging them into standalone native apps.

## Showcase

| Android | iOS | Harmony |
| ---- | ---- | ---- |
| ![Android](./static/android.jpg) | ![iOS](./static/ios.jpg) | ![Harmony](./static/harmony.jpg) |

## Getting Started

- [Mini Program Packaging Guide](./fe/packages/compiler/README.md)
- [Android Integration Guide](./android/README.md)
- [iOS Integration Guide](./iOS/README.md)
- [Harmony Integration Guide](./harmony/dimina/README.md)

## Contributing

Dimina is designed in accordance with the [Mini App Standard White Paper](https://www.w3.org/TR/mini-app-white-paper/) and currently aligns with most of the WeChat Mini Program's feature interfaces.

Thanks to the high similarity between Vue 3 and mini program syntax, Dimina's underlying view rendering framework is built on Vue. The framework uses a custom compiler to transform mini program syntax into Vue syntax, implements a full set of standard mini program Vue components, and finally loads and displays views through mini program containers on major mobile platforms.

For more information about the compiler's underlying principles, implementation details, and the interaction logic between the logic layer and the message channel, please refer to the [documentation](./docs/README.md).

For currently supported capabilities, see the [Dimina capability reference guide](./docs/API-Reference.md).

As the mini program ecosystem has evolved over the years, Dimina does not yet fully support all **APIs/components/features** of mini programs. Contributions and suggestions are highly welcome!

## Star Trend

If you find Dimina helpful, please click the ⭐Star button in the upper right to support us and help more people discover this project.

[![Star History Chart](https://api.star-history.com/svg?repos=didi/dimina&type=Date)](https://star-history.com/#didi/dimina&Date)

## License

Dimina is distributed and used under the [Apache-2.0](https://opensource.org/license/apache-2-0) license. For more details, please see the [LICENSE](LICENSE) file.
