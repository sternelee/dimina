# 星河小程序前端框架

## 项目结构

本项目由多个包组成：

- **compiler**：小程序源码编译工具。
- **container**：原生容器层，为小程序提供 API。
- **service**：逻辑层（JavaScript 运行时、worker 线程、消息通道）。
- **render**：渲染层，负责 UI 展示与消息处理。
- **components**：内置标准组件。
- **common**：通用工具函数。
- **server**：网络请求代理服务器。

## Requirements

建议使用 Node 18+, pnpm 8+。

## Getting Started

### Install

```sh
# Install dependencies
pnpm install
```

### Development

```sh

# Build (development, no minify)
pnpm build:dev

# Compile all Mini Programs in example/
pnpm compile

# Build (production, minified)
pnpm build

# Preview production build
pnpm preview

# Compile a specific Mini Program (in packages/compiler)
npm link
# Then in example/xx
dmcc build

# Web development
pnpm dev

# Native container debugging
pnpm dev:native

# Run tests
pnpm test
```

### compiler 编译工具

See below for usage:

```sh
Usage: dmcc build -c <source_dir> -s <output_dir> -w # watch mode

File mapping:
- app.js, index.js → logic.js
- index.wxml → view.js
- app.wxss, index.wxss → style.css
- app.json, index.json → config.json
```
