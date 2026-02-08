# iOS 模块说明（统一版）

本目录包含 Aliang 的 iOS 客户端工程与 Swift Package。

## 1. 快速运行

```bash
cd ios
./start_ios.sh
```

`start_ios.sh` 会：
- 启动基础设施（PostgreSQL / Redis / MinIO）
- 检查后端健康状态；若未启动则尝试后台拉起
- 打开 `AliangHostApp.xcodeproj`

在 Xcode 中：
- Scheme: `AliangHostApp`
- Simulator: iPhone 15+
- 运行：`Cmd + R`

## 2. 本地联调默认地址

默认 API 地址来自：

- `ios/Sources/AliangIOS/Core/Config/AppConfig.swift`

默认值：`http://localhost:8080`

如需连接云端，请改为你的 API 域名（`https://...`）。

## 3. 测试

### Swift Package 测试（推荐）

```bash
cd ios
swift test
```

### Xcode 测试

```bash
cd ios
./run_tests_xcode.sh
```

可选环境变量：
- `IOS_SCHEME`（默认 `AliangIOS`）
- `IOS_TEST_DESTINATION`（如 `platform=iOS Simulator,name=iPhone 15`）

## 4. 常见问题

### 后端不可用

先在仓库根目录检查：

```bash
curl http://localhost:8080/health
```

### iOS 无法请求云端 API

- 检查 `AppConfig.swift` 默认地址
- 检查 API 是否可公网访问
- 检查 HTTPS 证书是否有效

## 5. 相关文档

- 总览：`README.md`
- 快速启动：`GETTING_STARTED.md`
- 部署：`DEPLOYMENT.md`
