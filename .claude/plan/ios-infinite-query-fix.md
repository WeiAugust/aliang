# 修复计划：iOS 客户端无限查询问题

## 问题描述

iOS 客户端启动后不停查询服务端，功能无法正常使用。日志显示持续的数据库查询：
- `SELECT * FROM "post_media" WHERE "post_media"."post_id" IN (5,4,3,2,1)`
- `SELECT * FROM "users" WHERE "users"."id" = 1`

## 问题根因分析

### 1. 缺少刷新互斥机制 (高优先级)

**文件**: `ios/Sources/AliangIOS/Features/Feed/ViewModels/FeedViewModel.swift`

`loadInitial()` 和 `refresh()` 没有互斥，可能同时执行：
- `loadInitial()` 只检查 `!isLoading`
- `refresh()` 只检查 `!isRefreshing`
- 两者可能同时执行，导致重复查询

### 2. 缺少状态变化检测 (中优先级)

**文件**: `ios/Sources/AliangIOS/Features/Feed/Views/PostDetailView.swift:118-120`

```swift
.onChange(of: interactionViewModel.state) { _, newState in
    onInteractionStateChange?(newState)
}
```

没有检测 `oldValue != newState`，重复的状态值会触发不必要的更新。

### 3. PostPublished 通知机制不完整 (中优先级)

**文件**: `ios/Sources/AliangIOS/App/MainTabView.swift:67-69`

监听 `"PostPublished"` 通知，但 **没有任何地方发送这个通知**。

### 4. 潜在的状态竞争条件

当 `posts` 数组被修改时，SwiftUI 可能重新渲染视图，触发 `.task` 或 `.refreshable` 再次调用刷新逻辑。

## 修复方案

### Step 1: 添加刷新互斥机制

**文件**: `ios/Sources/AliangIOS/Features/Feed/ViewModels/FeedViewModel.swift`

```swift
public func loadInitial() async {
    guard !isLoading, !isRefreshing else {
        return
    }
    isLoading = true
    defer { isLoading = false }
    // ... existing code
}

public func refresh() async {
    guard !isLoading, !isRefreshing else {
        return
    }
    isRefreshing = true
    defer { isRefreshing = false }
    // ... existing code
}
```

### Step 2: 添加状态变化检测

**文件**: `ios/Sources/AliangIOS/Features/Feed/Views/PostDetailView.swift`

```swift
.onChange(of: interactionViewModel.state) { oldValue, newValue in
    guard oldValue != newValue else { return }
    onInteractionStateChange?(newValue)
}
```

### Step 3: 实现 PostPublished 通知

**文件**: `ios/Sources/AliangIOS/Features/Composer/Views/ComposerView.swift`

在发布成功后发送通知：

```swift
Button(viewModel.isPublishing ? "Publishing..." : "Publish") {
    Task {
        _ = await viewModel.publish()
        if viewModel.publishSuccessPostID != nil {
            NotificationCenter.default.post(
                name: NSNotification.Name("PostPublished"),
                object: nil
            )
        }
    }
}
```

### Step 4: 添加刷新防抖 (可选)

在高频刷新场景下添加防抖机制。

## 涉及文件

| 文件 | 操作 | 描述 |
|------|------|------|
| `ios/Sources/AliangIOS/Features/Feed/ViewModels/FeedViewModel.swift` | 修改 | 添加刷新互斥 |
| `ios/Sources/AliangIOS/Features/Feed/Views/PostDetailView.swift` | 修改 | 添加 onChange 检测 |
| `ios/Sources/AliangIOS/Features/Composer/Views/ComposerView.swift` | 修改 | 发送 PostPublished 通知 |

## 验证步骤

1. 构建项目：`xcodebuild -scheme AliangHostApp build`
2. 启动后端和 iOS 模拟器
3. 观察服务端日志，确认没有持续重复的查询
4. 测试发布帖子后 Feed 是否正确刷新

## 风险评估

- **低风险**: 修改主要是添加 guard 检查和状态检测
- **注意**: 确保通知发送不会导致循环触发
