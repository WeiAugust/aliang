# iOS 模拟器冒烟清单（2026-02-09）

## 环境
- 日期：2026-02-09
- 分支：`ios-smoke-qa-fixes-20260208`
- 设备：`iPhone 16e Simulator (iOS 26.2)`
- 后端：`http://localhost:8080`（健康检查通过）

## 冒烟链路
目标链路：`登录 → 发纯文本 → 搜索 → 评论 → 分页`

### 1) 登录
- 接口：`POST /api/v1/auth/sms/send` + `POST /api/v1/auth/sms/verify`
- 结果：通过
- 记录：成功获取用户 token，`user_id=1`

### 2) 发纯文本帖子
- 接口：`POST /api/v1/posts`
- 发送体（纯文本场景）：`post_type=image` + `media_urls=[]`
- 结果：通过
- 记录：成功创建帖子 `post_id=10`

### 3) 搜索帖子内容
- 接口：`GET /api/v1/search?q=...`
- 查询词：`ios smoke text only`
- 结果：通过
- 记录：命中 `post_id=10`

### 4) 评论
- 接口：`POST /api/v1/posts/:id/comments` + `GET /api/v1/posts/:id/comments`
- 结果：通过
- 记录：成功创建评论 `comment_id=8`，列表可查到该评论

### 5) 分页
- 接口：`GET /api/v1/posts?offset=0&limit=1` + `GET /api/v1/posts?offset=1&limit=1`
- 结果：通过
- 记录：`page0_first=10`，`page1_first=9`，分页游标生效

## 发现与优化

### 问题
- `ios/run_tests_xcode.sh` 原实现在测试阶段调用了无 test action 的 scheme，导致脚本失败：
  - `xcodebuild: error: Scheme AliangIOS is not currently configured for the test action.`

### 修复
- 更新 `ios/run_tests_xcode.sh`：
  1. Xcode 阶段只负责 Host App 模拟器构建（`AliangHostApp`）
  2. 测试阶段改为 Swift Package tests（按集成与核心模块分层）
  3. 支持 destination 自动探测与覆盖变量

## 回归结果
- `swift test --package-path ios`：130 passed, 0 failed
- `cd ios && ./run_tests_xcode.sh`：通过
- 模拟器构建与启动：通过
