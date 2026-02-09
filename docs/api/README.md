# API 文档（统一版）

本文件基于当前代码路由（`backend/internal/router/router.go`）整理。

- Health: `http://localhost:8080/health`
- Readiness: `http://localhost:8080/ready`
- Base URL: `http://localhost:8080/api/v1`

## 1. 认证说明

- 业务接口使用 JWT Bearer：`Authorization: Bearer <token>`
- 普通用户登录：短信验证码流程
- 管理员登录：用户名密码流程

## 2. 响应格式

成功示例：

```json
{
  "success": true,
  "data": {}
}
```

失败示例：

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "..."
  }
}
```

## 3. 全量路由清单

### 3.1 健康检查

- `GET /health`
- `GET /ready`

### 3.2 认证

- `POST /api/v1/auth/sms/send`
- `POST /api/v1/auth/sms/verify`
- `POST /api/v1/admin/auth/login`

### 3.3 用户

- `GET /api/v1/users/me`（需登录）
- `PUT /api/v1/users/me`（需登录）
- `GET /api/v1/users/:id`（需登录）
- `GET /api/v1/users/:id/posts`（需登录）

### 3.4 帖子

- `GET /api/v1/posts`
- `GET /api/v1/posts/:id`
- `POST /api/v1/posts`（需登录）
- `DELETE /api/v1/posts/:id`（需登录）
- `POST /api/v1/posts/:id/like`（需登录）
- `GET /api/v1/posts/:id/comments`（需登录）
- `POST /api/v1/posts/:id/comments`（需登录）

### 3.5 评论

- `DELETE /api/v1/comments/:id`（需登录）

### 3.6 搜索与话题

- `GET /api/v1/search?q=...`
- `GET /api/v1/hashtags/trending`
- `GET /api/v1/hashtags/:name/posts`

> 当 `ES_ENABLED=true` 时，`/api/v1/search` 优先走 Elasticsearch；失败会自动回退数据库搜索。

### 3.7 上传

- `POST /api/v1/upload/image`（需登录，multipart）
- `POST /api/v1/upload/video`（需登录，multipart）

### 3.8 管理员

以下都需：已登录 + admin 角色。

- `GET /api/v1/admin/stats`
- `GET /api/v1/admin/posts`
- `PUT /api/v1/admin/posts/:id/visibility`
- `PUT /api/v1/admin/posts/:id/label`
- `DELETE /api/v1/admin/posts/:id`
- `GET /api/v1/admin/users`
- `GET /api/v1/admin/users/:id`

## 4. 核心流程示例

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

### 4.2 创建帖子（`media_urls`）

```bash
BASE=http://localhost:8080/api/v1
TOKEN=<your_user_token>

curl -X POST "$BASE/posts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title":"Hello",
    "content":"Hello #demo",
    "post_type":"image",
    "media_urls":[]
  }'
```

> `post_type=image` 最多 9 张图；`post_type=video` 必须 1 个视频 URL。

### 4.3 图片上传并发帖

```bash
BASE=http://localhost:8080/api/v1
TOKEN=<your_user_token>

IMAGE_URL=$(curl -s -X POST "$BASE/upload/image" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/image.png" | jq -r '.data.url')

curl -X POST "$BASE/posts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"Image\",\"content\":\"#image\",\"post_type\":\"image\",\"media_urls\":[\"$IMAGE_URL\"]}"
```

### 4.4 管理员登录与拉取帖子

```bash
BASE=http://localhost:8080/api/v1

ADMIN_TOKEN=$(curl -s -X POST "$BASE/admin/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.data.token')

curl "$BASE/admin/posts?offset=0&limit=20" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

## 5. 已知约束

- 短信登录需先 `send` 再 `verify`。
- 管理员账号默认 `admin / admin123`；若历史库不兼容，请执行 `GETTING_STARTED.md` / `DEPLOYMENT.md` 中的初始化 SQL。
- 当前仓库未提供 `cmd/migrate/main.go`。

## 6. 相关文档

- 快速启动：`GETTING_STARTED.md`
- 部署：`DEPLOYMENT.md`
- 架构：`docs/architecture/README.md`
