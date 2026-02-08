# Aliang 快速启动指南（统一版）

目标：让你快速启动 `iOS / Backend / Admin`，并在本地或云端完整体验核心功能。

---

## 1. 启动目标

- Backend API：`http://localhost:8080`
- Admin：`http://localhost:3000`
- iOS：Xcode 运行 `AliangHostApp`
- 基础设施：PostgreSQL / Redis / MinIO

---

## 2. 前置要求

- Docker（含 Compose 插件）
- Go 1.22+
- Node.js 20+
- Xcode 15+（仅 iOS 需要）
- 推荐工具：`jq`

快速检查：

```bash
docker --version
docker compose version
go version
node --version
npm --version
```

---

## 3. 本地快速启动（推荐）

### 3.1 拉代码

```bash
git clone https://github.com/WeiAugust/aliang.git
cd aliang
```

### 3.2 启动基础设施

```bash
docker compose up -d
docker compose ps
```

### 3.3 启动 Backend

```bash
cd backend
cp -n .env.example .env
go mod download
make dev
```

新终端验证：

```bash
curl http://localhost:8080/health
```

### 3.4 启动 Admin

```bash
cd admin
npm ci
npm run dev
```

访问：`http://localhost:3000`

### 3.5 启动 iOS

```bash
cd ios
./start_ios.sh
```

脚本会自动：
- 启动基础设施
- 检查/启动后端
- 打开 `AliangHostApp.xcodeproj`

---

## 4. 10 分钟端到端体验

### 4.1 用户短信登录

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
  -d '{"title":"Quick Start Post","content":"Hello #quickstart","post_type":"image","media_urls":[]}' | jq -r '.data.id')

curl -X POST "$BASE/posts/$POST_ID/like" \
  -H "Authorization: Bearer $TOKEN"

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

如登录失败，执行管理员初始化：

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

## 5. 本地访问入口

| 组件 | 地址 | 说明 |
|------|------|------|
| Backend Health | `http://localhost:8080/health` | 健康检查 |
| Backend API | `http://localhost:8080/api/v1` | 业务 API |
| Admin | `http://localhost:3000` | 管理后台 |
| MinIO Console | `http://localhost:9001` | `minioadmin / minioadmin123` |
| PostgreSQL | `localhost:5432` | `aliang / aliang123` |
| Redis | `localhost:6379` | 默认无密码 |

---

## 6. 云端快速部署（摘要）

推荐组合：
- 云主机：`backend + postgres + redis + minio`
- Vercel：`admin`
- iOS：改默认 API 地址后直连云端

详细步骤见：`DEPLOYMENT.md`

---

## 7. 常见问题

### Q1：`make migrate-up` 报错找不到 `cmd/migrate/main.go`

当前仓库未包含数据库迁移入口文件，`migrate-up` 和 `migrate-down` 命令暂不可用。开发环境可直接 `make dev` 启动服务。

如需启用迁移功能，需创建 `cmd/migrate/main.go` 文件。

### Q2：短信登录失败

必须先 `send` 再 `verify`。

### Q3：端口冲突

```bash
lsof -i :8080
lsof -i :3000
lsof -i :5432
lsof -i :6379
lsof -i :9000
```

---

## 8. 停止与重置

```bash
# 停止基础设施
docker compose down

# 完全重置（会清空数据）
docker compose down -v
```

---

## 9. 相关文档

- 项目入口：`README.md`
- 云部署：`DEPLOYMENT.md`
- API：`docs/api/README.md`
- 架构：`docs/architecture/README.md`
- iOS：`ios/README.md`
