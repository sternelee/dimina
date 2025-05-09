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

## 环境要求

建议使用 Node 18+, pnpm 8+。

## 开始上手

### 安装说明

```sh
# Install dependencies
pnpm install
```

### 开发说明

```sh
# Compile all Mini Programs in example/
pnpm compile

# Build (development, no minify)
pnpm build:dev

# Build (production, minified)
pnpm build

# Preview production build
pnpm preview

# Web development
pnpm dev

# Native container debugging
pnpm dev:native

# Run tests
pnpm test
```

### dmcc 编译工具

请参考[编译工具使用说明](./packages/compiler/README.md)。
