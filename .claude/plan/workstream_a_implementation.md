# Workstream A 实施计划

**创建日期:** 2026-02-08
**状态:** 待用户批准

---

## 概述

实现后端核心功能修复，包括post创建、可见性控制、admin安全和管理指标。

---

## 任务 A1: 统一 Post 创建协议 (P0)

### 目标
对齐iOS和后端的media处理协议，将 `media_ids` 改为 `media_urls`，并在创建post时持久化media记录。

### 修改文件

#### 1. `backend/internal/handler/post_handler.go`
```go
// 修改 CreatePostRequest
type CreatePostRequest struct {
    Title      string   `json:"title" binding:"required"`
    Content    string   `json:"content" binding:"required"`
    PostType   string   `json:"post_type" binding:"required,oneof=image video"`
    MediaURLs  []string `json:"media_urls"`  // 从 media_ids 改为 media_urls
}
```

#### 2. `backend/internal/service/post_service.go`
- 添加 `postMediaRepo` 依赖
- 在 `Create()` 方法中添加media持久化逻辑
- 修改 `Create()` 签名接收 `mediaURLs []string` 参数

#### 3. 新建 `backend/internal/repository/post_media_repository.go`
```go
// PostMediaRepository 接口
type PostMediaRepository interface {
    Create(ctx context.Context, postMedia *model.PostMedia) error
    DeleteByPostID(ctx context.Context, postID int64) error
    ListByPostID(ctx context.Context, postID int64) ([]*model.PostMedia, error)
}
```

#### 4. 修改 `main.go` 依赖注入
- 初始化 `PostMediaRepository`

### 数据流
```
iOS → POST /api/v1/posts { media_urls: ["url1", "url2"] }
    → post_handler 解析请求
    → post_service.Create(post, mediaURLs)
    → 创建 post 记录
    → 遍历 mediaURLs 创建 post_media 记录
```

---

## 任务 A2: 服务器端 Post 规则验证 (P0)

### 目标
在服务端强制执行media规则：最多9张图片或1个视频。

### 验证规则
1. `post_type = image`: `len(mediaURLs) <= 9`
2. `post_type = video`: `len(mediaURLs) == 1`
3. 所有media的URL必须是有效且可访问的
4. 拒绝混合类型 (image + video)

### 修改文件

`backend/internal/service/post_service.go`:
```go
func (s *PostService) Create(ctx context.Context, post *model.Post, mediaURLs []string) error {
    // 验证media规则
    if err := validateMedia(post.PostType, mediaURLs); err != nil {
        return err
    }

    // 创建post
    if err := s.postRepo.Create(ctx, post); err != nil {
        return fmt.Errorf("failed to create post: %w", err)
    }

    // 持久化media记录
    for i, url := range mediaURLs {
        postMedia := &model.PostMedia{
            PostID:    post.ID,
            MediaURL:  url,
            MediaType: post.PostType,
            SortOrder: i,
        }
        if err := s.postMediaRepo.Create(ctx, postMedia); err != nil {
            return fmt.Errorf("failed to create post media: %w", err)
        }
    }

    // ... hashtag处理
}

func validateMedia(postType string, mediaURLs []string) error {
    switch postType {
    case "image":
        if len(mediaURLs) > 9 {
            return fmt.Errorf("image post can have at most 9 images, got %d", len(mediaURLs))
        }
    case "video":
        if len(mediaURLs) != 1 {
            return fmt.Errorf("video post must have exactly 1 video, got %d", len(mediaURLs))
        }
    }
    return nil
}
```

---

## 任务 A3: 修复可见性授权 (P0)

### 目标
确保 `self_only` post只能被所有者或admin访问。

### 问题分析
| Endpoint | 问题 |
|----------|------|
| `GET /posts/:id` | 任何人都可以查看self_only post |
| `GET /users/:id/posts` | 任何人都可以查看self_only post |
| `GET /admin/posts` | 只能看到public post，应看到全部 |

### 修改文件

#### 1. `backend/internal/repository/post_repository.go`
```go
// 增加 visibility 过滤的 GetByID 方法
func (r *postRepository) GetByIDWithVisibility(ctx context.Context, id int64, userID int64, isAdmin bool) (*model.Post, error) {
    var post model.Post

    // 构建查询条件
    query := r.db.WithContext(ctx).
        Preload("User").
        Preload("Media").
        Preload("Hashtags").
        First(&post, id)

    // 如果不是admin且不是所有者，隐藏self_only post
    if !isAdmin && post.UserID != userID {
        query.Where("visibility != ?", "self_only")
    }

    if err := query.Error; err != nil {
        return nil, err
    }
    return &post, nil
}

// 增加 visibility 过滤的 ListByUserID 方法
func (r *postRepository) ListByUserIDWithVisibility(ctx context.Context, userID, viewerID int64, isAdmin bool, offset, limit int) ([]*model.Post, error) {
    var posts []*model.Post

    query := r.db.WithContext(ctx).
        Preload("User").
        Preload("Media").
        Where("user_id = ? AND deleted_at IS NULL", userID)

    // 如果不是admin且不是所有者，隐藏self_only post
    if !isAdmin && userID != viewerID {
        query.Where("visibility != ?", "self_only")
    }

    err := query.
        Offset(offset).
        Limit(limit).
        Order("created_at DESC").
        Find(&posts).Error

    return posts, err
}

// Admin获取所有posts (不需要visibility过滤)
func (r *postRepository) ListAllForAdmin(ctx context.Context, offset, limit int) ([]*model.Post, error) {
    var posts []*model.Post
    err := r.db.WithContext(ctx).
        Preload("User").
        Preload("Media").
        Where("deleted_at IS NULL").
        Offset(offset).
        Limit(limit).
        Order("created_at DESC").
        Find(&posts).Error
    return posts, err
}
```

#### 2. `backend/internal/service/post_service.go`
- 添加带visibility检查的查询方法

#### 3. `backend/internal/handler/post_handler.go`
```go
func (h *PostHandler) GetPost(c *gin.Context) {
    // ... ID解析

    // 获取当前用户ID
    currentUserID, _ := middleware.GetUserID(c)
    isAdmin := middleware.IsAdmin(c)

    post, err := h.postService.GetByIDWithVisibility(c.Request.Context(), id, currentUserID, isAdmin)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "success": false,
            "error": gin.H{
                "code":    "NOT_FOUND",
                "message": "Post not found or access denied",
            },
        })
        return
    }
    // ...
}
```

#### 4. `backend/internal/handler/user_handler.go`
- 修改 `GetUserPosts` 添加visibility检查

#### 5. `backend/internal/handler/admin_handler.go`
- 修改 `GetPosts` 使用 `ListAllForAdmin`

---

## 任务 A4: 保护 Admin 登录 (P0)

### 目标
实现bcrypt密码哈希验证，添加 `password_hash` 字段。

### 修改文件

#### 1. `backend/internal/model/models.go`
```go
type User struct {
    // ... 现有字段
    PasswordHash string `gorm:"size:255" json:"-"` // 不返回给客户端
}
```

#### 2. 新建 `backend/migrations/000009_add_password_hash.up.sql`
```sql
ALTER TABLE users ADD COLUMN password_hash VARCHAR(255);

-- 更新admin用户密码 (bcrypt hash of "admin123")
-- 使用: htpasswd -nbBC 10 "" admin123 | cut -d: -f2
UPDATE users SET password_hash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZRGdjGj/nMskyB.B5.iQfknx5mDGa' WHERE role = 'admin';
```

#### 3. 新建 `backend/migrations/000009_add_password_hash.down.sql`
```sql
ALTER TABLE users DROP COLUMN password_hash;
```

#### 4. `backend/internal/service/auth_service.go`
```go
import "golang.org/x/crypto/bcrypt"

// 在 AuthService 中添加 bcrypt 依赖
func (s *AuthService) AdminLogin(ctx context.Context, username, password string) (string, *model.User, error) {
    user, err := s.userRepo.GetByPhone(ctx, username)
    if err != nil {
        return "", nil, fmt.Errorf("invalid credentials")
    }

    if user.Role != "admin" {
        return "", nil, fmt.Errorf("invalid credentials")
    }

    // 验证密码
    if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
        return "", nil, fmt.Errorf("invalid credentials")
    }

    // 生成JWT token
    token, err := s.jwtManager.GenerateToken(user.ID, user.Phone, user.Role)
    if err != nil {
        return "", nil, fmt.Errorf("failed to generate token: %w", err)
    }

    return token, user, nil
}
```

#### 5. `backend/internal/repository/user_repository.go`
- 添加 `UpdatePassword(userID int64, newHash string)` 方法

---

## 任务 A5: 实现真实 Admin 指标 (P1)

### 目标
计算真实的日活跃用户数和日新增帖子数。

### 修改文件

#### 1. `backend/internal/repository/user_repository.go`
```go
// GetDailyActiveUsers 获取过去24小时有活动的用户数
func (r *userRepository) GetDailyActiveUsers(ctx context.Context) (int64, error) {
    var count int64
    // 查询过去24小时有登录、点赞、评论或发帖的用户
    err := r.db.WithContext(ctx).
        Model(&model.User{}).
        Where("updated_at >= NOW() - INTERVAL '24 hours'").
        Count(&count).Error
    return count, err
}
```

#### 2. `backend/internal/repository/post_repository.go`
```go
// GetDailyNewPosts 获取过去24小时的新帖子数
func (r *postRepository) GetDailyNewPosts(ctx context.Context) (int64, error) {
    var count int64
    err := r.db.WithContext(ctx).
        Model(&model.Post{}).
        Where("created_at >= NOW() - INTERVAL '24 hours'").
        Count(&count).Error
    return count, err
}
```

#### 3. `backend/internal/service/user_service.go`
```go
func (s *UserService) GetDailyActiveUsers(ctx context.Context) (int64, error) {
    return s.userRepo.GetDailyActiveUsers(ctx)
}
```

#### 4. `backend/internal/service/post_service.go`
```go
func (s *PostService) GetDailyNewPosts(ctx context.Context) (int64, error) {
    return s.postRepo.GetDailyNewPosts(ctx)
}
```

#### 5. `backend/internal/handler/admin_handler.go`
```go
func (h *AdminHandler) GetStats(c *gin.Context) {
    ctx := c.Request.Context()

    userCount, _ := h.userService.Count(ctx)
    postCount, _ := h.postService.Count(ctx)
    likeCount, _ := h.interactionService.CountTotalLikes(ctx)
    commentCount, _ := h.interactionService.CountTotalComments(ctx)
    dailyActiveUsers, _ := h.userService.GetDailyActiveUsers(ctx)
    dailyNewPosts, _ := h.postService.GetDailyNewPosts(ctx)

    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "data": gin.H{
            "total_users":        userCount,
            "total_posts":        postCount,
            "total_likes":        likeCount,
            "total_comments":     commentCount,
            "daily_active_users": dailyActiveUsers,
            "daily_new_posts":    dailyNewPosts,
        },
    })
}
```

---

## 任务 A6: 添加 Readiness 检查 (P1)

### 目标
实现 `/ready` 端点检查PostgreSQL、Redis、MinIO连接。

### 修改文件

#### 1. `backend/internal/handler/health_handler.go` (新建)
```go
package handler

import (
    "context"
    "net/http"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/redis/go-redis/v9"
    "github.com/aws/aws-sdk-go/aws"
    "github.com/aws/aws-sdk-go/aws/session"
    "github.com/aws/aws-sdk-go/service/s3manager"
    "github.com/aws/aws-sdk-go/service/s3"

    "github.com/WeiAugust/aliang/backend/internal/config"
)

type HealthHandler struct {
    db      *gorm.DB
    redis   *redis.Client
    cfg     *config.Config
}

// NewHealthHandler creates a new health handler
func NewHealthHandler(db *gorm.DB, redis *redis.Client, cfg *config.Config) *HealthHandler {
    return &HealthHandler{
        db:    db,
        redis: redis,
        cfg:   cfg,
    }
}

// Readiness checks if all dependencies are ready
func (h *HealthHandler) Readiness(c *gin.Context) {
    ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
    defer cancel()

    checks := make(map[string]string)

    // Check PostgreSQL
    sqlDB, err := h.db.DB()
    if err != nil {
        checks["postgresql"] = "unhealthy"
    } else {
        if err := sqlDB.PingContext(ctx); err != nil {
            checks["postgresql"] = "unhealthy"
        } else {
            checks["postgresql"] = "ready"
        }
    }

    // Check Redis
    if err := h.redis.Ping(ctx).Err(); err != nil {
        checks["redis"] = "unhealthy"
    } else {
        checks["redis"] = "ready"
    }

    // Check MinIO/S3
    sess, err := session.NewSession(&aws.Config{
        Region:           aws.String(h.cfg.AWS.Region),
        Endpoint:         aws.String(h.cfg.AWS.Endpoint),
        DisableSSL:       aws.Bool(h.cfg.AWS.DisableSSL),
        S3ForcePathStyle: aws.Bool(true),
    })
    if err != nil {
        checks["storage"] = "unhealthy"
    } else {
        svc := s3.New(sess)
        _, err := svc.ListObjectsV2WithContext(ctx, &s3.ListObjectsV2Input{
            Bucket: aws.String(h.cfg.AWS.Bucket),
            MaxKeys: aws.Int64(1),
        })
        if err != nil {
            checks["storage"] = "unhealthy"
        } else {
            checks["storage"] = "ready"
        }
    }

    // Determine overall status
    allReady := true
    for _, status := range checks {
        if status != "ready" {
            allReady = false
            break
        }
    }

    status := http.StatusOK
    if !allReady {
        status = http.StatusServiceUnavailable
    }

    c.JSON(status, gin.H{
        "status":   "ready",
        "checks":   checks,
    })
}
```

#### 2. `backend/internal/router/router.go`
```go
// 添加 Readiness 端点
engine.GET("/ready", func(c *gin.Context) {
    // ... 委托给 healthHandler
})
```

---

## 实施顺序

根据用户选择，采用并行开发策略：

1. **第一组**: A1 + A2 (Post创建相关)
2. **第二组**: A3 (可见性安全)
3. **第三组**: A4 (Admin安全)
4. **第四组**: A5 + A6 (指标和健康检查)

---

## 依赖关系

- A1 → A2: A1完成后A2才能正确测试
- A3: 独立，可并行
- A4: 独立，可并行
- A5: 独立，可并行
- A6: 独立，可并行

---

## 测试策略

1. **A1/A2**: 单元测试验证media验证逻辑
2. **A3**: 集成测试验证visibility泄露修复
3. **A4**: 单元测试验证bcrypt验证
4. **A5**: 手动验证指标计算
5. **A6**: 手动验证各依赖检查

---

## 风险

1. **A4**: 需要数据库迁移，现有admin用户可能无法登录
    - 缓解: 提供migration回滚脚本
2. **A3**: 可能影响现有API行为
    - 缓解: 充分测试admin端点
