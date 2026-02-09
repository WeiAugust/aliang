# 项目状态（统一版）

**最后更新**：2026-02-08  
**总体状态**：核心功能可本地跑通，文档与脚本已统一。

---

## 1. 当前完成度

### Backend

- 认证：短信登录、管理员登录
- 内容：发帖（`media_urls`）、删帖、可见性控制
- 互动：点赞、评论
- 搜索：关键词、话题趋势、话题帖子
- 健康检查：`/health`、`/ready`

### Admin

- 管理员登录
- 数据看板
- 帖子管理（查看/标记/可见性/删除）
- 用户管理（列表、详情）

### iOS

- 登录、信息流、发帖、互动、个人页、搜索话题
- 具备 `start_ios.sh` 一键联调入口

---

## 2. 文档统一情况

已统一以下文档口径（命令、变量名、流程）：

- `README.md`
- `GETTING_STARTED.md`
- `DEPLOYMENT.md`
- `docs/api/README.md`
- `docs/architecture/README.md`
- `docs/deployment/README.md`
- `docs/deployment/VERCEL_DEPLOYMENT.md`
- `ios/README.md`

统一点包括：
- 优先使用 `docker compose`
- Admin 环境变量使用 `VITE_API_BASE_URL`
- 登录流程明确为 `send -> verify`
- 发帖协议统一为 `media_urls`

---

## 3. 脚本统一情况

已统一以下脚本行为：

- `start.sh`
- `test_upload.sh`
- `ios/start_ios.sh`
- `ios/run_tests_xcode.sh`

统一点包括：
- 自动识别 `docker compose` / `docker-compose`
- 输出一致化
- 避免引用不存在文档
- 与最新 API 协议一致

---

## 4. 已知待办

- `backend/Makefile` 中 `make migrate-up` 依赖 `cmd/migrate/main.go`，仓库尚未提供该入口。
- 生产环境仍需补充：HTTPS、监控告警、备份策略等。

---

## 5. 推荐下一步

1. 补齐迁移入口（`backend/cmd/migrate/main.go`）。
2. 增加部署后自动验收脚本（health + auth + post + admin）。
3. 在 CI 中加入文档一致性检查（关键变量名/命令关键字扫描）。
