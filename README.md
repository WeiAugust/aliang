# Aliang - Community Content System

[![CI](https://github.com/WeiAugust/aliang/workflows/CI/badge.svg)](https://github.com/WeiAugust/aliang/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Aliang 是一个社区内容平台，当前仓库包含：
- `backend/`：Go + Gin API
- `admin/`：React + Vite 管理台
- `ios/`：SwiftUI 客户端（iOS 17+）
- `docker-compose.yml`：PostgreSQL / Redis / Elasticsearch / MinIO 本地依赖

## 文档入口

- 快速启动（本地联调 + 端到端体验）：`GETTING_STARTED.md`
- 云部署：`DEPLOYMENT.md`
- API 文档：`docs/api/README.md`
- 架构文档：`docs/architecture/README.md`

## 技术栈（按当前代码）

| 组件 | 技术 | 说明 |
|------|------|------|
| Backend | Go 1.23+ + Gin | REST API |
| Database | PostgreSQL 16 | 关系数据 |
| Cache | Redis 7 | 验证码与缓存 |
| Search | Elasticsearch 8.x（可选启用） | 搜索加速 |
| Storage | MinIO | 图片/视频对象存储 |
| Admin | React 18 + TypeScript + Vite | 管理后台 |
| iOS | Swift 5.9+ / SwiftUI | iOS 客户端 |

## 本地快速启动

### 前置要求

- Docker（含 Compose）
- Go 1.23+
- Node.js 20+
- Xcode 15+（仅 iOS）
- 推荐：`jq`

### 方式 A：一键启动后端（仅 Backend + 基础设施）

```bash
git clone https://github.com/WeiAugust/aliang.git
cd aliang
./start.sh
```

> `start.sh` 会拉起容器并前台运行 `backend`。若要启动 Admin，请新开终端执行 `cd admin && npm ci && npm run dev`。

### 方式 B：手动分模块启动（推荐调试）

```bash
git clone https://github.com/WeiAugust/aliang.git
cd aliang
docker compose up -d

cd backend
cp -n .env.example .env
go mod download
make dev
```

新终端启动 Admin：

```bash
cd admin
npm ci
npm run dev
```

如需启动 iOS：

```bash
cd ios
./start_ios.sh
```

## 本地访问地址

- Backend Health：`http://localhost:8080/health`
- Backend Ready：`http://localhost:8080/ready`
- Backend API：`http://localhost:8080/api/v1`
- Admin：`http://localhost:3000`
- MinIO Console：`http://localhost:9001`（`minioadmin / minioadmin123`）

## 测试账号

- 短信登录（Mock）：`13800138000 / 123456`
- Admin：`admin / admin123`

> 短信登录顺序必须是 `send -> verify`。

## 常用开发命令

```bash
# backend
cd backend
make dev
make test
make lint
make build

# admin
cd admin
npm run dev
npm test
npm run lint
npm run build

# iOS
cd ios
swift test
./run_tests_xcode.sh
```

## 迁移与数据初始化说明

- 迁移入口已存在：`backend/cmd/migrate/main.go`
- 推荐命令：

```bash
cd backend
go run cmd/migrate/main.go -up
go run cmd/migrate/main.go -down -step=1
```

- `make migrate-up` / `make migrate-down` 当前参数传递方式与迁移程序 flag 不一致，建议直接使用上面的 `go run ... -up/-down`。
- `make dev` 在非 `release` 模式下会执行 GORM AutoMigrate（用于开发便利，不替代正式迁移流程）。

## 目录结构

```text
aliang/
├── backend/
├── admin/
├── ios/
├── docs/
├── README.md
├── GETTING_STARTED.md
├── DEPLOYMENT.md
└── docker-compose.yml
```
