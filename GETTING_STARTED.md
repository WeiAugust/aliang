# Getting Started with Aliang

This guide will help you set up and run the Aliang Community Content System locally.

---

## Prerequisites

### Required Software
- **Go 1.22+** - Backend API
- **Node.js 18+** - Admin panel
- **Docker & Docker Compose** - Infrastructure services

### Installation

**macOS:**
```bash
# Install Go
brew install go

# Install Node.js
brew install node

# Install Docker Desktop
# Download from https://www.docker.com/products/docker-desktop
```

**Verify installations:**
```bash
go version      # Should show 1.22+
node --version  # Should show 18+
docker --version
docker-compose --version
```

---

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/WeiAugust/aliang.git
cd aliang
```

### 2. Start Infrastructure Services
```bash
# Start PostgreSQL, Redis, MinIO
docker-compose up -d

# Verify services are running
docker-compose ps

# Expected output:
# - aliang-postgres (healthy)
# - aliang-redis (healthy)
# - aliang-minio (healthy)
```

### 3. Start Backend API
```bash
cd backend

# Install dependencies
go mod download

# Copy environment file
cp .env.example .env

# Run the API
go run cmd/api/main.go

# Expected output:
# {"level":"info","msg":"Starting server","address":"0.0.0.0:8080"}
```

### 4. Start Admin Panel
```bash
# In a new terminal
cd admin

# Install dependencies
npm install

# Start development server
npm run dev

# Expected output:
# VITE ready in xxx ms
# Local: http://localhost:3000
```

### 5. Test the Setup
```bash
# Health check
curl http://localhost:8080/health
# Expected: {"status":"healthy"}

# Login
curl -X POST http://localhost:8080/api/v1/auth/sms/verify \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}'

# Open admin panel
# URL: http://localhost:3000
# Login: admin / admin123
```

---

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Backend API | http://localhost:8080 | - |
| Admin Panel | http://localhost:3000 | admin / admin123 |
| MinIO Console | http://localhost:9001 | minioadmin / minioadmin123 |
| PostgreSQL | localhost:5432 | aliang / aliang123 |
| Redis | localhost:6379 | (no password) |

---

## Test Accounts

### Admin Panel
- **Username**: `admin`
- **Password**: `admin123`

### Mobile App (Mock SMS)
- **Phone**: `13800138000`
- **Verification Code**: `123456` (always works in development)

---

## Development Workflow

### Backend Development
```bash
cd backend

# Run in development mode
go run cmd/api/main.go

# Run tests
go test ./...

# Run with coverage
go test -cover ./...

# Format code
go fmt ./...

# Run linters
go vet ./...

# Build binary
go build -o bin/api cmd/api/main.go
```

### Admin Panel Development
```bash
cd admin

# Start dev server (hot reload)
npm run dev

# Run tests
npm test

# Run linters
npm run lint

# Fix linting issues
npm run lint:fix

# Build for production
npm run build
```

### Database Operations
```bash
# View logs
docker-compose logs postgres

# Connect to database
docker-compose exec postgres psql -U aliang -d aliang

# Run migrations
cd backend
make migrate-up

# Rollback migrations
make migrate-down
```

---

## Common Tasks

### Create a Post
```bash
# 1. Login to get token
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/sms/verify \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}' | jq -r '.data.token')

# 2. Create post
curl -X POST http://localhost:8080/api/v1/posts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title":"My First Post",
    "content":"Hello world! #test #hello",
    "post_type":"text"
  }'
```

### Upload Media
```bash
# Upload image
curl -X POST http://localhost:8080/api/v1/upload/image \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/image.jpg"

# Upload video
curl -X POST http://localhost:8080/api/v1/upload/video \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/video.mp4"
```

### Search Posts
```bash
# Search by keyword
curl "http://localhost:8080/api/v1/search?q=hello"

# Get trending hashtags
curl http://localhost:8080/api/v1/hashtags/trending

# Get posts by hashtag
curl http://localhost:8080/api/v1/hashtags/test/posts
```

---

## Troubleshooting

### Backend won't start

**Issue**: `go: command not found`
```bash
# Solution: Install Go
brew install go
```

**Issue**: Database connection error
```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# View logs
docker-compose logs postgres

# Restart PostgreSQL
docker-compose restart postgres
```

**Issue**: Redis connection error
```bash
# Check if Redis is running
docker-compose ps redis

# Test connection
docker-compose exec redis redis-cli ping
# Should return: PONG
```

### Admin Panel won't start

**Issue**: `npm: command not found`
```bash
# Solution: Install Node.js
brew install node
```

**Issue**: Port 3000 already in use
```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>
```

**Issue**: Dependencies installation fails
```bash
# Clear cache and reinstall
cd admin
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

### Docker Issues

**Issue**: Services won't start
```bash
# Stop all containers
docker-compose down

# Remove volumes
docker-compose down -v

# Restart
docker-compose up -d
```

**Issue**: Port conflicts
```bash
# Check what's using the ports
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis
lsof -i :9000  # MinIO

# Stop conflicting services or change ports in docker-compose.yml
```

---

## Next Steps

### For Developers
1. Read [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines
2. Check [docs/api/README.md](docs/api/README.md) for API documentation
3. Review [docs/architecture/README.md](docs/architecture/README.md) for system design

### For Testing
1. Run the test suite: `cd backend && go test ./...`
2. Check test coverage: `go test -cover ./...`
3. Run integration tests: `./test_upload.sh`

### For Deployment
1. Read [docs/deployment/README.md](docs/deployment/README.md)
2. Configure production environment variables
3. Set up SSL certificates
4. Deploy with Docker Compose or Kubernetes

---

## Useful Commands

```bash
# Start everything
docker-compose up -d && cd backend && go run cmd/api/main.go

# Stop everything
docker-compose down

# View all logs
docker-compose logs -f

# Restart a service
docker-compose restart postgres

# Clean up
docker-compose down -v
make clean

# Run tests
make test

# Run linters
make lint

# Build for production
make build
```

---

## Support

- **Documentation**: Check the `docs/` directory
- **Issues**: Report bugs on GitHub Issues
- **API Reference**: See `docs/api/README.md`
- **Architecture**: See `docs/architecture/README.md`

---

**Ready to start?** Run: `docker-compose up -d && cd backend && go run cmd/api/main.go` 🚀
