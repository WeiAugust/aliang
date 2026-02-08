# Next Steps Guide

## 🎯 Immediate Actions

### 1. Install Go (Required)

The backend is complete but requires Go to run.

```bash
# macOS
brew install go

# Verify installation
go version  # Should show 1.22 or higher

# Set up Go environment (if needed)
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
```

### 2. Install Backend Dependencies

```bash
cd backend

# Download all Go dependencies
go mod download

# Verify dependencies
go mod tidy

# This should complete without errors
```

### 3. Start Infrastructure Services

```bash
# From project root
docker-compose up -d

# Verify all services are running
docker-compose ps

# Expected output:
# - aliang-postgres (healthy)
# - aliang-redis (healthy)
# - aliang-minio (healthy)

# Check logs if any service is not healthy
docker-compose logs postgres
docker-compose logs redis
docker-compose logs minio
```

### 4. Configure Environment

```bash
cd backend

# Copy environment template
cp .env.example .env

# The default values work for local development
# No changes needed unless you want to customize

# Key settings:
# - DB credentials match docker-compose.yml
# - Redis and MinIO endpoints point to localhost
# - JWT_SECRET should be changed for production
# - SMS_MOCK_ENABLED=true for development
```

### 5. Run the Backend

```bash
cd backend

# Option 1: Run directly with go run
go run cmd/api/main.go

# Option 2: Build and run
go build -o bin/api cmd/api/main.go
./bin/api

# Expected output:
# - "Database connection established"
# - "Redis connection established"
# - "MinIO connection established"
# - "Starting server on 0.0.0.0:8080"
```

### 6. Test the API

Open a new terminal and test the endpoints:

```bash
# Health check
curl http://localhost:8080/health

# Expected: {"status":"healthy"}

# Send SMS verification code
curl -X POST http://localhost:8080/api/v1/auth/sms/send \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'

# Expected: {"success":true,"data":{"code":"123456",...}}

# Login with verification code
curl -X POST http://localhost:8080/api/v1/auth/sms/verify \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}'

# Expected: {"success":true,"data":{"token":"eyJ...","user":{...}}}

# Save the token from the response
TOKEN="<token-from-response>"

# Get current user profile (protected endpoint)
curl http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN"

# Expected: {"success":true,"data":{"id":1,"phone":"13800138000",...}}

# Create a post (protected endpoint)
curl -X POST http://localhost:8080/api/v1/posts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title":"My First Post",
    "content":"Hello world! #test #hello",
    "post_type":"image"
  }'

# Expected: {"success":true,"data":{"id":1,...}}

# Get all posts (public endpoint)
curl http://localhost:8080/api/v1/posts

# Expected: {"success":true,"data":{"items":[...],"has_more":false}}

# Search posts
curl "http://localhost:8080/api/v1/search?q=hello"

# Expected: {"success":true,"data":{"items":[...],"has_more":false}}

# Get trending hashtags
curl http://localhost:8080/api/v1/hashtags/trending

# Expected: {"success":true,"data":[{"name":"test","post_count":1},...]}
```

### 7. Test Admin Endpoints

```bash
# Admin login
curl -X POST http://localhost:8080/api/v1/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Expected: {"success":true,"data":{"token":"eyJ...","admin":{...}}}

# Save the admin token
ADMIN_TOKEN="<admin-token-from-response>"

# Get dashboard statistics
curl http://localhost:8080/api/v1/admin/stats \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Expected: {"success":true,"data":{"total_users":1,"total_posts":1,...}}

# Get all posts (admin)
curl http://localhost:8080/api/v1/admin/posts \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Expected: {"success":true,"data":{"items":[...],"has_more":false}}

# Update post visibility
curl -X PUT http://localhost:8080/api/v1/admin/posts/1/visibility \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"visibility":"self_only"}'

# Expected: {"success":true,"message":"Post visibility updated"}

# Update post label
curl -X PUT http://localhost:8080/api/v1/admin/posts/1/label \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"label":"recommended"}'

# Expected: {"success":true,"message":"Post label updated"}
```

### 8. Start Admin Panel

```bash
cd admin

# Install dependencies (first time only)
npm install

# Start development server
npm run dev

# Expected output:
# - "VITE v5.x.x ready in xxx ms"
# - "Local: http://localhost:3000"

# Open browser to http://localhost:3000
# Login with: admin / admin123
```

---

## 📱 iOS Parallel Development Plan

Backend APIs are ready. To speed up iOS delivery, split work into parallel branches:

### Branch Tracks (parallel execution)

1. **Track A: Foundation** (`feat/ios-00-foundation`)
   - Xcode project scaffold, SwiftUI app shell
   - API client + unified error model
   - Keychain token store + app session bootstrap
   - **Done when**: simulator build passes + networking unit tests pass

2. **Track B: Auth** (`feat/ios-01-auth`)
   - Phone input, SMS code, login/logout flow
   - Integrate `/api/v1/auth/sms/send` and `/api/v1/auth/sms/verify`
   - **Depends on**: Track A
   - **Done when**: auth ViewModel tests + login UI smoke test pass

3. **Track C: Feed** (`feat/ios-02-feed`)
   - Feed list, pull-to-refresh, infinite scroll
   - Post detail navigation
   - Integrate `/api/v1/posts` and `/api/v1/posts/:id`
   - **Depends on**: Track A
   - **Done when**: pagination and render tests pass

4. **Track D: Composer & Media** (`feat/ios-03-compose-media`)
   - Image/video picker, upload progress, retry
   - Integrate `/api/v1/upload/image`, `/api/v1/upload/video`, `/api/v1/posts`
   - **Depends on**: Track A (token flow aligned after Track B)
   - **Done when**: upload validation tests + publish smoke test pass

5. **Track E: Interactions** (`feat/ios-04-interactions`)
   - Like/unlike, comment list/input, optimistic UI rollback
   - **Depends on**: Track B + Track C
   - **Done when**: interaction state tests + comment flow UI tests pass

6. **Track F: Integration & QA** (`feat/ios-05-integration-qa`)
   - Rebase and integrate B/C/D/E
   - Regression flow: login → feed → publish → like/comment
   - **Merge rule**: only merge to `main` after all tracks pass test gates

### Suggested Merge Order

`feat/ios-00-foundation` → `feat/ios-01-auth` + `feat/ios-02-feed` + `feat/ios-03-compose-media` → `feat/ios-04-interactions` → `feat/ios-05-integration-qa` → `main`

### Branch Workflow Template

```bash
# Create branch
git checkout -b feat/ios-02-feed

# Keep branch up-to-date
git fetch origin
git rebase origin/main

# Before PR
# 1) run branch test gates
# 2) complete PR checklist
# 3) request review and merge
```

---

## 🔧 Development Workflow

### Making Changes to Backend

```bash
cd backend

# 1. Make your changes to the code

# 2. Format code
go fmt ./...

# 3. Run linters
go vet ./...

# 4. Run tests (when implemented)
go test ./...

# 5. Build to check for compilation errors
go build -o bin/api cmd/api/main.go

# 6. Run the application
go run cmd/api/main.go
```

### Making Changes to Admin Panel

```bash
cd admin

# 1. Make your changes to the code

# 2. Run linter
npm run lint

# 3. Fix linting issues
npm run lint:fix

# 4. Run tests (when implemented)
npm test

# 5. Build to check for errors
npm run build

# 6. Run development server
npm run dev
```

### Database Migrations

When you need to modify the database schema:

```bash
cd backend

# 1. Create a new migration file
# migrations/000009_your_migration_name.up.sql
# migrations/000009_your_migration_name.down.sql

# 2. Write the SQL for the migration

# 3. Run migrations (when migration runner is implemented)
# For now, GORM auto-migration handles schema changes
```

---

## 📦 Next Feature: Media Upload

The backend is complete except for actual file upload handling. Here's how to implement it:

### Step 1: Create StorageService

Create `backend/internal/service/storage_service.go`:

```go
package service

import (
    "context"
    "fmt"
    "io"
    "path/filepath"

    "github.com/minio/minio-go/v7"
)

type StorageService struct {
    minioClient *minio.Client
    bucket      string
}

func NewStorageService(minioClient *minio.Client, bucket string) *StorageService {
    return &StorageService{
        minioClient: minioClient,
        bucket:      bucket,
    }
}

func (s *StorageService) UploadImage(ctx context.Context, filename string, reader io.Reader, size int64) (string, error) {
    // Generate unique filename
    objectName := fmt.Sprintf("images/%s", filename)

    // Upload to MinIO
    _, err := s.minioClient.PutObject(ctx, s.bucket, objectName, reader, size, minio.PutObjectOptions{
        ContentType: "image/jpeg",
    })
    if err != nil {
        return "", err
    }

    // Return URL
    url := fmt.Sprintf("http://localhost:9000/%s/%s", s.bucket, objectName)
    return url, nil
}

func (s *StorageService) UploadVideo(ctx context.Context, filename string, reader io.Reader, size int64) (string, error) {
    // Similar to UploadImage but for videos
    objectName := fmt.Sprintf("videos/%s", filename)

    _, err := s.minioClient.PutObject(ctx, s.bucket, objectName, reader, size, minio.PutObjectOptions{
        ContentType: "video/mp4",
    })
    if err != nil {
        return "", err
    }

    url := fmt.Sprintf("http://localhost:9000/%s/%s", s.bucket, objectName)
    return url, nil
}
```

### Step 2: Create UploadHandler

Create `backend/internal/handler/upload_handler.go`:

```go
package handler

import (
    "net/http"

    "github.com/gin-gonic/gin"

    "github.com/WeiAugust/aliang/backend/internal/service"
)

type UploadHandler struct {
    storageService *service.StorageService
}

func NewUploadHandler(storageService *service.StorageService) *UploadHandler {
    return &UploadHandler{
        storageService: storageService,
    }
}

func (h *UploadHandler) UploadImage(c *gin.Context) {
    file, err := c.FormFile("file")
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error": gin.H{
                "code":    "VALIDATION_ERROR",
                "message": "No file uploaded",
            },
        })
        return
    }

    // Open file
    src, err := file.Open()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "success": false,
            "error": gin.H{
                "code":    "INTERNAL_ERROR",
                "message": "Failed to open file",
            },
        })
        return
    }
    defer src.Close()

    // Upload to storage
    url, err := h.storageService.UploadImage(c.Request.Context(), file.Filename, src, file.Size)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "success": false,
            "error": gin.H{
                "code":    "INTERNAL_ERROR",
                "message": "Failed to upload file",
            },
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "data": gin.H{
            "url":           url,
            "thumbnail_url": url, // TODO: Generate thumbnail
        },
    })
}

func (h *UploadHandler) UploadVideo(c *gin.Context) {
    // Similar to UploadImage
}
```

### Step 3: Register Upload Routes

Update `backend/internal/router/router.go`:

```go
// Add to Router struct
uploadHandler *handler.UploadHandler

// Add to NewRouter parameters
uploadHandler *handler.UploadHandler,

// Add to Setup() method
upload := v1.Group("/upload")
upload.Use(middleware.AuthMiddleware(r.jwtManager))
{
    upload.POST("/image", r.uploadHandler.UploadImage)
    upload.POST("/video", r.uploadHandler.UploadVideo)
}
```

### Step 4: Wire in main.go

Update `backend/cmd/api/main.go`:

```go
// Initialize storage service
storageService := service.NewStorageService(minioClient, cfg.MinIO.Bucket)

// Initialize upload handler
uploadHandler := handler.NewUploadHandler(storageService)

// Pass to router
r := router.NewRouter(
    authHandler,
    userHandler,
    postHandler,
    interactionHandler,
    searchHandler,
    adminHandler,
    uploadHandler,  // Add this
    jwtManager,
    logger,
    cfg,
)
```

---

## 🧪 Testing Strategy

### Unit Tests

Create test files for each service:

```bash
# Example: backend/internal/service/auth_service_test.go
cd backend

# Run tests
go test ./internal/service/...

# Run with coverage
go test -cover ./internal/service/...

# Generate coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html
```

### Integration Tests

Create integration tests for handlers:

```bash
# Example: backend/internal/handler/auth_handler_test.go
cd backend

# Run integration tests
go test ./internal/handler/...
```

### E2E Tests

Use the admin panel's Playwright tests:

```bash
cd admin

# Run E2E tests
npm run test:e2e
```

---

## 🚀 Deployment

### Production Checklist

Before deploying to production:

- [ ] Change JWT_SECRET to a strong random value
- [ ] Disable SMS_MOCK_ENABLED
- [ ] Set up real SMS provider (Twilio, AWS SNS, etc.)
- [ ] Configure production database credentials
- [ ] Set up SSL certificates
- [ ] Configure production CORS origins
- [ ] Set up monitoring and logging
- [ ] Configure backup strategy
- [ ] Set up CI/CD pipeline
- [ ] Run security audit
- [ ] Load test the API

### Docker Deployment

```bash
# Build Docker images
docker-compose -f docker-compose.prod.yml build

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Check logs
docker-compose -f docker-compose.prod.yml logs -f
```

---

## 📚 Additional Resources

### Documentation
- API Documentation: `docs/api/README.md`
- Architecture: `docs/architecture/README.md`
- Deployment: `docs/deployment/README.md`

### Code Structure
- Models: `backend/internal/model/`
- Repositories: `backend/internal/repository/`
- Services: `backend/internal/service/`
- Handlers: `backend/internal/handler/`
- Middleware: `backend/internal/middleware/`

### Configuration
- Backend: `backend/.env.example`
- Admin: `admin/.env.example`
- Docker: `docker-compose.yml`

---

## 🐛 Troubleshooting

### Backend won't start

```bash
# Check if Go is installed
go version

# Check if dependencies are installed
cd backend
go mod download

# Check if services are running
docker-compose ps

# Check logs
docker-compose logs postgres
docker-compose logs redis
docker-compose logs minio

# Verify environment variables
cd backend
cat .env
```

### Database connection error

```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres

# Test connection
docker-compose exec postgres psql -U aliang -d aliang

# Verify credentials in .env match docker-compose.yml
```

### Redis connection error

```bash
# Check if Redis is running
docker-compose ps redis

# Test connection
docker-compose exec redis redis-cli ping

# Should return: PONG
```

### MinIO connection error

```bash
# Check if MinIO is running
docker-compose ps minio

# Access MinIO console
# Open http://localhost:9001
# Login: minioadmin / minioadmin123

# Check if bucket exists
docker-compose exec minio mc ls local/
```

### Admin panel won't start

```bash
# Check if Node.js is installed
node --version

# Install dependencies
cd admin
rm -rf node_modules package-lock.json
npm install

# Check for port conflicts
lsof -i :3000

# Start with verbose logging
npm run dev -- --debug
```

---

## 🎉 Success Criteria

You'll know everything is working when:

✅ Backend starts without errors
✅ Health check returns `{"status":"healthy"}`
✅ You can login with phone `13800138000` and code `123456`
✅ You can create a post
✅ You can see the post in the feed
✅ You can like and comment on the post
✅ Admin panel loads at http://localhost:3000
✅ You can login to admin panel with `admin/admin123`
✅ Dashboard shows statistics
✅ You can manage posts and users

---

## 💡 Tips

1. **Keep services running**: Leave `docker-compose up -d` running while developing
2. **Use hot reload**: The backend will need manual restart, but admin panel has hot reload
3. **Check logs**: Use `docker-compose logs -f` to monitor service logs
4. **Use Postman**: Import the API endpoints into Postman for easier testing
5. **Read the docs**: All documentation is in the `docs/` directory

---

## 🆘 Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Review the logs: `docker-compose logs -f`
3. Check the documentation in `docs/`
4. Review the code comments
5. Check GitHub issues (when repository is public)

---

**Ready to start?** Run: `cd backend && go run cmd/api/main.go` 🚀
