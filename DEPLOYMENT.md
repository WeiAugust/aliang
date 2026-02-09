# Aliang 部署指南（统一版）

本指南与 `README.md`、`GETTING_STARTED.md` 保持一致。

---

## 1. 推荐部署架构

- 云主机（Docker）：`backend + postgres + redis + minio`
- Vercel：`admin`
- iOS：连接云端 API

---

## 2. 云主机部署 Backend + 基础设施

### 2.1 准备环境

- Ubuntu 22.04+（建议）
- Docker + Docker Compose Plugin（`docker compose`）
- 对外可访问的 API 地址（IP 或域名）

### 2.2 拉取代码

```bash
git clone https://github.com/WeiAugust/aliang.git
cd aliang/backend
```

### 2.3 配置 `backend/.env.docker`

```bash
cp -n .env.example .env
vim .env.docker
```

至少修改以下变量：

```env
JWT_SECRET=replace-with-a-strong-secret
CORS_ALLOWED_ORIGINS=https://your-admin.vercel.app
```

> MinIO 变量名使用 `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY`。

### 2.4 启动服务

```bash
docker compose up -d --build
```

验证：

```bash
curl http://<你的API地址>:8080/health
curl http://<你的API地址>:8080/ready
```

---

## 3. 部署 Admin（Vercel）

Vercel 项目配置：
- Root Directory：`admin`
- Build Command：`npm run build`
- Output Directory：`dist`

环境变量：

```env
VITE_API_BASE_URL=https://api.yourdomain.com/api/v1
```

> 变量名必须是 `VITE_API_BASE_URL`。

---

## 4. iOS 连接云端 API

修改 `ios/Sources/AliangIOS/Core/Config/AppConfig.swift`：

```swift
public init(baseAPIURL: URL = URL(string: "https://api.yourdomain.com")!) {
    self.baseAPIURL = baseAPIURL
}
```

重新运行 `AliangHostApp`。

---

## 5. 管理员初始化（仅在登录失败时）

```bash
ADMIN_HASH=$(docker run --rm httpd:2.4-alpine htpasswd -nbBC 10 "" admin123 | tr -d ':\n')

docker exec -i aliang-postgres psql -U aliang -d aliang <<SQL
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);
INSERT INTO users (phone, nickname, avatar_url, bio, role, status, password_hash)
VALUES ('admin', 'Administrator', '', 'System Administrator', 'admin', 'active', '$ADMIN_HASH')
ON CONFLICT (phone) DO UPDATE SET role='admin', password_hash='$ADMIN_HASH';
SQL
```

验证：

```bash
BASE=https://api.yourdomain.com/api/v1
curl -X POST "$BASE/admin/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

---

## 6. 上线后验收（建议）

### 6.1 用户登录

```bash
BASE=https://api.yourdomain.com/api/v1

curl -X POST "$BASE/auth/sms/send" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'

curl -X POST "$BASE/auth/sms/verify" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}'
```

### 6.2 发帖与互动

```bash
BASE=https://api.yourdomain.com/api/v1

curl -s -X POST "$BASE/auth/sms/send" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}' >/dev/null

TOKEN=$(curl -s -X POST "$BASE/auth/sms/verify" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}' | jq -r '.data.token')

POST_ID=$(curl -s -X POST "$BASE/posts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Cloud Quick Start","content":"Hello #cloud","post_type":"image","media_urls":[]}' | jq -r '.data.id')

curl -X POST "$BASE/posts/$POST_ID/like" -H "Authorization: Bearer $TOKEN"
curl -X POST "$BASE/posts/$POST_ID/comments" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content":"Looks good"}'

curl "$BASE/search?q=Cloud"
curl "$BASE/hashtags/cloud/posts"
```

### 6.3 Admin API 验证

```bash
BASE=https://api.yourdomain.com/api/v1

ADMIN_TOKEN=$(curl -s -X POST "$BASE/admin/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.data.token')

curl "$BASE/admin/posts?offset=0&limit=10" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## 7. 自托管 Admin（可选）

```bash
cd aliang/admin

docker build \
  --build-arg VITE_API_BASE_URL=https://api.yourdomain.com/api/v1 \
  -t aliang-admin:latest .

docker run -d \
  --name aliang-admin \
  -p 80:80 \
  --restart unless-stopped \
  aliang-admin:latest
```

---

## 8. 已知事项

- `backend/Makefile` 中 `make migrate-up` 依赖 `cmd/migrate/main.go`，当前仓库未包含该入口。
- 非 `GIN_MODE=release` 下后端会执行 GORM 自动建表。

---

## 9. 文档索引

- 快速启动：`GETTING_STARTED.md`
- 项目总览：`README.md`
- Vercel 细节：`docs/deployment/VERCEL_DEPLOYMENT.md`
