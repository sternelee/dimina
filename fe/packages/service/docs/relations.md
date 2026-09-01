# 组件间关系（Relations）

## 概述

Dimina 支持组件之间的 `parent` / `child` 和 `ancestor` / `descendant` 关系，并提供关系回调与 `getRelationNodes()`。

## 功能特性

### 1. 支持的关系类型

- `parent`：当前组件的直接父组件
- `child`：当前组件的直接子组件
- `ancestor`：当前组件的祖先组件
- `descendant`：当前组件的后代组件

### 2. 关系生命周期

- `linked`：关系建立时调用
- `linkChanged`：已关联组件移动时调用
- `unlinked`：关系断开时调用

### 3. 路径解析

- 支持相对路径：`./component`、`../sibling/component`
- 支持绝对路径：`/path/to/component`
- 自动解析路径映射关系

### 4. Behavior 支持

- 支持通过 `target` 属性指定目标 behavior
- 自动合并 behavior 中的 relations 配置

## API 参考

### getRelationNodes(relationPath)

获取指定关系路径对应的所有关联节点。

```javascript
// 获取所有子组件
const children = this.getRelationNodes('./child-component')

// 获取父组件
const parents = this.getRelationNodes('./parent-component')
```

**参数：**
- `relationPath` (string): 关系路径，必须与 relations 配置中的路径一致

**返回值：**
- Array: 关联组件实例数组

## 使用示例

### 基本父子关系

```javascript
// 父组件
Component({
  relations: {
    './child-component': {
      type: 'child',
      linked: function(target) {
        console.log('子组件已连接:', target)
        // 可以直接调用子组件方法
        target.updateFromParent(this.data.someValue)
      },
      unlinked: function(target) {
        console.log('子组件已断开:', target)
      }
    }
  },
  
  methods: {
    updateAllChildren: function() {
      const children = this.getRelationNodes('./child-component')
      children.forEach(child => {
        child.updateFromParent(this.data.someValue)
      })
    }
  }
})

// 子组件
Component({
  relations: {
    './parent-component': {
      type: 'parent',
      linked: function(target) {
        this.parent = target
      }
    }
  },
  
  methods: {
    updateFromParent: function(value) {
      this.setData({ parentValue: value })
    },
    
    notifyParent: function(data) {
      if (this.parent) {
        this.parent.handleChildEvent(data)
      }
    }
  }
})
```

### 祖先-后代关系

```javascript
// 祖先组件
Component({
  relations: {
    './descendant-component': {
      type: 'descendant',
      linked: function(target) {
        this.descendants = this.descendants || []
        this.descendants.push(target)
      }
    }
  },
  
  methods: {
    broadcastMessage: function(message) {
      const descendants = this.getRelationNodes('./descendant-component')
      descendants.forEach(descendant => {
        descendant.receiveMessage(message)
      })
    }
  }
})

// 后代组件
Component({
  relations: {
    './ancestor-component': {
      type: 'ancestor',
      linked: function(target) {
        this.ancestor = target
      }
    }
  },
  
  methods: {
    receiveMessage: function(message) {
      console.log('收到祖先消息:', message)
    }
  }
})
```

### 使用 Behavior

```javascript
const childBehavior = Behavior({})

const parentBehavior = Behavior({
  relations: {
    './child-component': {
      type: 'child',
      target: childBehavior,
      linked: function(target) {
        console.log('具有 childBehavior 的组件已连接')
      }
    }
  }
})

Component({
  behaviors: [parentBehavior],
  // 其他配置...
})

// 被关联的子组件需要声明同一个 behavior
Component({
  behaviors: [childBehavior]
})
```

## 实现细节

### 1. 关系初始化

- 在组件构造时调用 `#initRelations()` 初始化关系配置
- 解析关系路径并存储映射关系
- 为每个关系路径初始化节点数组

### 2. 关系建立

- 在组件 `attached` 生命周期后立即建立关系
- 遍历所有实例查找匹配的组件
- 根据关系类型和路径匹配建立连接
- 调用 `linked` 生命周期函数
- **双向关系建立**: 当组件 attached 时，会通知其他组件重新检查关系，确保双向关系正确建立

### 3. 关系维护

- 组件移动时触发 `linkChanged` 函数
- 组件销毁时自动断开所有关系
- 调用 `unlinked` 生命周期函数

### 4. 路径解析算法

```javascript
#resolveRelationPath(relationPath) {
  if (relationPath.startsWith('./')) {
    // 相对路径处理
    const currentDir = this.is.substring(0, this.is.lastIndexOf('/'))
    return `${currentDir}/${relationPath.substring(2)}`
  } else if (relationPath.startsWith('../')) {
    // 上级路径处理
    // 解析 .. 路径段
  } else {
    // 绝对路径
    return relationPath
  }
}
```

## 测试覆盖

现有测试覆盖以下场景：

- 父子关系建立和断开
- 祖先与后代关系建立
- 关系回调调用
- 组件销毁时清理关系
- 相对路径解析
- `getRelationNodes()`
- 父组件先创建、子组件后创建时的双向关系建立

## 注意事项

1. 组件在 `attached` 阶段检查关系，并通知已经存在的实例重新匹配，因此父子组件的创建顺序不影响已覆盖的场景。
2. 组件 `detached` 回调执行完后才触发 relation `unlinked`，随后清理双方保存的关系引用。
3. 关系回调的异常会被隔离并交给组件错误处理，不会中断剩余关系遍历。
4. `getRelationNodes()` 的参数必须与 `relations` 中声明的原始路径一致；未声明的路径返回 `null`。

## 兼容性边界

当前实现覆盖本文列出的关系类型、路径、回调和查询 API。迁移依赖 relations 的组件时，仍需验证 behavior `target`、组件移动、动态创建和销毁顺序等实际用例。

## 参考文档

- [微信小程序组件间关系官方文档](https://developers.weixin.qq.com/miniprogram/dev/framework/custom-component/relations.html)
- [Dimina relations 回归测试](../__tests__/relations.spec.js)
