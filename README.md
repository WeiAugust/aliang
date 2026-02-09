# Aliang - Community Content System

[![CI](https://github.com/WeiAugust/aliang/workflows/CI/badge.svg)](https://github.com/WeiAugust/aliang/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Aliang 是一个社区内容平台，包含：
- iOS 客户端（SwiftUI）
- Web Admin 管理台（React + Vite）
- Backend API（Go + Gin）
- PostgreSQL / Redis / MinIO 基础设施

## 统一文档入口

- 快速启动（本地 + 云 + 全功能体验）：`GETTING_STARTED.md`
- 云部署（推荐架构与验收流程）：`DEPLOYMENT.md`
- API 文档（接口清单与示例）：`docs/api/README.md`
- 架构文档：`docs/architecture/README.md`

## 技术栈

| 组件 | 技术 | 说明 |
|------|------|------|
| Backend | Go 1.22+ + Gin | REST API |
| Database | PostgreSQL 16 | 关系型数据 |
| Cache | Redis 7 | 缓存与会话 |
| Search | Elasticsearch 8.x（可选） | 帖子全文检索 |
| Storage | MinIO | 图片/视频对象存储 |
| iOS | Swift 5.9+ / SwiftUI | iOS 17+ 客户端 |
| Admin | React 18 + TypeScript + Vite | 管理后台 |
| Infra | Docker + Docker Compose | 本地与云部署 |

## 本地 5 分钟启动

### 前置要求

- Docker（含 Compose 插件）
- Go 1.22+
- Node.js 20+
- Xcode 15+（仅 iOS 需要）
- 推荐：`jq`

### 1) 启动基础设施

```bash
git clone https://github.com/WeiAugust/aliang.git
cd aliang
docker compose up -d
docker compose ps
```

### 2) 启动 Backend

```bash
cd backend
cp -n .env.example .env
go mod download
make dev
```

验证：

```bash
curl http://localhost:8080/health
```

### 3) 启动 Admin

```bash
cd admin
npm ci
npm run dev
```

打开：`http://localhost:3000`

### 4) 启动 iOS

```bash
cd ios
./start_ios.sh
```

## 测试账号

- Admin：`admin / admin123`
- iOS 短信模拟：`13800138000 / 123456`

> 短信登录必须先 `POST /api/v1/auth/sms/send`，再 `POST /api/v1/auth/sms/verify`。

## 常用开发命令

### Backend

```bash
cd backend
make dev
make test
make lint
make build
```

### Admin

```bash
cd admin
npm run dev
npm test
npm run lint
npm run build
```

### iOS

```bash
cd ios
swift test
./run_tests_xcode.sh
```

## 部署概要

推荐组合：
- 云主机：`backend + postgres + redis + minio`
- Vercel：`admin`
- iOS：将默认 API 地址改为云端域名

详情见：`DEPLOYMENT.md`

## 已知事项

- `backend/Makefile` 中 `make migrate-up` 指向 `cmd/migrate/main.go`，当前仓库未包含该入口。
- 开发环境直接 `make dev` 时，后端会在非 release 模式下执行 GORM 自动建表。

## 目录结构

```text
aliang/
├── backend/
├── ios/
├── admin/
├── docs/
├── GETTING_STARTED.md
├── DEPLOYMENT.md
└── docker-compose.yml
```
