# Vercel 部署（Admin）

本文件为 `DEPLOYMENT.md` 的 Vercel 子流程。

## 1. Vercel 项目配置

在 Vercel 导入仓库后设置：

- Framework Preset: `Vite`
- Root Directory: `admin`
- Build Command: `npm run build`
- Output Directory: `dist`
- Install Command: `npm ci`

## 2. 必填环境变量

```env
VITE_API_BASE_URL=https://api.yourdomain.com/api/v1
```

> 变量名必须是 `VITE_API_BASE_URL`，不要使用 `VITE_API_URL`。

## 3. 推荐发布流程

1. 在 Vercel 完成首次部署。
2. 打开部署后的 Admin 页面。
3. 使用 `admin / admin123` 登录验证。
4. 若登录失败，按 `DEPLOYMENT.md` 的“管理员初始化”执行。

## 4. GitHub Actions（可选）

如果使用 Actions 自动部署，需要以下 Secrets：

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

## 5. 回滚

在 Vercel Dashboard → Deployments 选择历史版本并重新 Promote。
