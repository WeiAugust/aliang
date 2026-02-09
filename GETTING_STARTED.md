# Aliang 快速启动指南（基于当前工程）

目标：在本地快速跑通 `Backend + Admin + iOS`，并完成一轮端到端功能验收。

---

## 1. 启动结果（你将得到什么）

- Backend API：`http://localhost:8080/api/v1`
- Backend 健康检查：`http://localhost:8080/health`
- Backend 就绪检查：`http://localhost:8080/ready`
- Admin：`http://localhost:3000`
- iOS：Xcode 打开并运行 `AliangHostApp`
- 依赖服务：PostgreSQL / Redis / Elasticsearch / MinIO

---

## 2. 前置要求

- Docker（支持 `docker compose`）
- Go `1.23+`
- Node.js `20+`
- Xcode `15+`（仅 iOS）
- 建议安装：`jq`

快速检查：

```bash
docker --version
docker compose version
go version
node --version
npm --version
```

---

## 3. 本地启动方式

### 3.1 方式 A：一键拉起后端链路

```bash
git clone https://github.com/WeiAugust/aliang.git
cd aliang
./start.sh
```

说明：
- `start.sh` 会启动基础设施容器，并在前台执行 `cd backend && make dev`。
- 该方式适合快速验证后端；要继续跑 Admin/iOS，请使用下方步骤。

### 3.2 方式 B：手动分模块启动（推荐开发时使用）

#### 步骤 1）启动基础设施

```bash
git clone https://github.com/WeiAugust/aliang.git
cd aliang
docker compose up -d
docker compose ps
```

#### 步骤 2）启动 Backend

```bash
cd backend
cp -n .env.example .env
go mod download
make dev
```

可选：启用 Elasticsearch 搜索

```bash
# backend/.env
ES_ENABLED=true
ES_URL=http://localhost:9200
```

新终端验证后端：

```bash
curl http://localhost:8080/health
curl http://localhost:8080/ready
```

#### 步骤 3）启动 Admin

```bash
cd admin
npm ci
npm run dev
```

访问：`http://localhost:3000`

#### 步骤 4）启动 iOS（可选）

```bash
cd ios
./start_ios.sh
```

`start_ios.sh` 会：
- 拉起基础设施
- 检查后端健康；若未运行则尝试后台启动
- 打开 `AliangHostApp.xcodeproj`

---

## 4. 10 分钟端到端验收

### 4.1 用户短信登录（Mock）

```bash
BASE=http://localhost:8080/api/v1

curl -X POST "$BASE/auth/sms/send" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'

curl -X POST "$BASE/auth/sms/verify" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}'
```

### 4.2 发帖 + 互动 + 搜索

```bash
BASE=http://localhost:8080/api/v1

curl -s -X POST "$BASE/auth/sms/send" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}' >/dev/null

TOKEN=$(curl -s -X POST "$BASE/auth/sms/verify" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}' | jq -r '.data.token')

POST_ID=$(curl -s -X POST "$BASE/posts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Quick Start","content":"Hello #quickstart","post_type":"image","media_urls":[]}' | jq -r '.data.id')

curl -X POST "$BASE/posts/$POST_ID/like" -H "Authorization: Bearer $TOKEN"

curl -X POST "$BASE/posts/$POST_ID/comments" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content":"Nice post"}'

curl "$BASE/search?q=Quick%20Start"
curl "$BASE/hashtags/quickstart/posts"
```

### 4.3 Admin 登录

默认账号：`admin / admin123`

```bash
BASE=http://localhost:8080/api/v1

curl -X POST "$BASE/admin/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

如登录失败（历史库或未跑迁移），执行管理员初始化：

```bash
ADMIN_HASH=$(docker run --rm httpd:2.4-alpine htpasswd -nbBC 10 "" admin123 | tr -d ':\n')

docker compose exec -T postgres psql -U aliang -d aliang <<SQL
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);
INSERT INTO users (phone, nickname, avatar_url, bio, role, status, password_hash)
VALUES ('admin', 'Administrator', '', 'System Administrator', 'admin', 'active', '$ADMIN_HASH')
ON CONFLICT (phone) DO UPDATE SET role='admin', password_hash='$ADMIN_HASH';
SQL
```

---

## 5. 本地入口与默认凭据

| 组件 | 地址 | 说明 |
|------|------|------|
| Backend Health | `http://localhost:8080/health` | 存活检查 |
| Backend Ready | `http://localhost:8080/ready` | 依赖就绪检查 |
| Backend API | `http://localhost:8080/api/v1` | 业务 API |
| Admin | `http://localhost:3000` | 管理台 |
| MinIO Console | `http://localhost:9001` | `minioadmin / minioadmin123` |
| PostgreSQL | `localhost:5432` | `aliang / aliang123` |
| Redis | `localhost:6379` | 默认无密码 |
| Elasticsearch | `localhost:9200` | 默认可用，后端需显式启用 |

---

## 6. 迁移与初始化

当前仓库已包含迁移入口：`backend/cmd/migrate/main.go`。

建议直接执行：

```bash
cd backend
go run cmd/migrate/main.go -up
go run cmd/migrate/main.go -down -step=1
```

说明：
- `backend/Makefile` 中 `migrate-up/migrate-down` 目标当前参数形式与迁移程序 flag 形式不一致。
- 开发环境下 `make dev` 会执行 GORM `AutoMigrate`，但不包含完整数据迁移/种子流程。

---

## 7. 常见问题

### Q1：短信登录失败

- 确认顺序为 `send -> verify`。
- 确认 `backend/.env` 中 `SMS_MOCK_ENABLED=true`，`SMS_MOCK_CODE=123456`。

### Q2：Admin 登录失败

- 先确认是否跑过迁移（尤其是 `000008`/`000009`）。
- 或执行本指南中的管理员初始化 SQL。

### Q3：端口冲突

```bash
lsof -i :8080
lsof -i :3000
lsof -i :5432
lsof -i :6379
lsof -i :9000
lsof -i :9001
lsof -i :9200
```

### Q4：iOS 无法连云端 API

- 默认地址在 `ios/Sources/AliangIOS/Core/Config/AppConfig.swift`。
- 连接云端时将默认值改为 `https://your-api-domain`。

---

## 8. 停止与重置

```bash
# 停止基础设施
docker compose down

# 停止并清空容器卷数据（危险操作）
docker compose down -v
```

---

## 9. 相关文档

- 项目总览：`README.md`
- 云端部署：`DEPLOYMENT.md`
- API 文档：`docs/api/README.md`
- 架构文档：`docs/architecture/README.md`
- iOS 模块说明：`ios/README.md`
