# Aliang Backend Deployment Guide

A production-ready social media backend built with Go, Gin, PostgreSQL, Redis, and MinIO.

## Prerequisites

- Docker & Docker Compose
- Go 1.23+ (for local development)
- PostgreSQL 16+
- Redis 7+
- MinIO (or any S3-compatible storage)

## Quick Start with Docker

```bash
# 1. Clone and navigate
git clone https://github.com/WeiAugust/aliang.git
cd aliang

# 2. Configure environment
cp backend/.env.example backend/.env
# Edit backend/.env with your settings

# 3. Start all services
docker-compose up -d

# 4. Run migrations
docker-compose exec backend go run cmd/migrate/main.go up

# 5. Verify
curl http://localhost:8080/health
```

## Docker Compose Setup

Create `docker-compose.yml` in the project root:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: aliang
      POSTGRES_PASSWORD: aliang123
      POSTGRES_DB: aliang
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U aliang"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin123
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio_data:/data

  backend:
    build: ./backend
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      minio:
        condition: service_started
    env_file:
      - backend/.env
    volumes:
      - uploads_data:/app/uploads

volumes:
  postgres_data:
  minio_data:
  uploads_data:
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | PostgreSQL host | `localhost` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_USER` | Database user | `aliang` |
| `DB_PASSWORD` | Database password | `aliang123` |
| `DB_NAME` | Database name | `aliang` |
| `REDIS_HOST` | Redis host | `localhost` |
| `REDIS_PORT` | Redis port | `6379` |
| `MINIO_ENDPOINT` | MinIO endpoint | `localhost:9000` |
| `MINIO_ACCESS_KEY` | MinIO access key | `minioadmin` |
| `MINIO_SECRET_KEY` | MinIO secret key | `minioadmin123` |
| `SERVER_PORT` | Server port | `8080` |
| `JWT_SECRET` | JWT signing secret | - |

## Manual Deployment

### 1. Install Dependencies

```bash
cd backend
go mod download
```

### 2. Configure Database

```bash
# Create database
createdb aliang

# Run migrations
go run cmd/migrate/main.go up
```

### 3. Build and Run

```bash
# Build binary
make build

# Run
./bin/api
```

## Kubernetes Deployment

### Backend Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aliang-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: aliang-backend
  template:
    metadata:
      labels:
        app: aliang-backend
    spec:
      containers:
      - name: backend
        image: ghcr.io/wei august/aliang/backend:latest
        ports:
        - containerPort: 8080
        envFrom:
        - secretRef:
            name: aliang-secrets
        - configMapRef:
            name: aliang-config
```

### Secrets

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: aliang-secrets
type: Opaque
stringData:
  DB_PASSWORD: your-secure-password
  JWT_SECRET: your-jwt-secret
```

## CI/CD Pipeline

### GitHub Actions

The repository includes:

- **CI**: Runs on every push to `main`/`develop` and PRs
  - Backend tests with PostgreSQL and Redis
  - Code linting (go vet, staticcheck)
  - Docker image build test
  - Minimum 80% test coverage required

- **Release**: Runs when a version tag is pushed (`v*.*.*`)
  - Creates GitHub release with changelog
  - Builds and pushes Docker images to GHCR
  - Images tagged by version, major.minor, and latest

### Automated Deployment

1. Push code changes
2. GitHub Actions runs CI checks
3. Create release tag: `git tag v1.0.0 && git push origin v1.0.0`
4. Release workflow builds and pushes Docker images
5. Pull new images in your deployment environment

## Health Check

```bash
curl http://localhost:8080/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## API Documentation

### Base URL

- Development: `http://localhost:8080`
- Production: `https://api.yourdomain.com`

### Authentication

All protected endpoints require JWT token in Authorization header:

```
Authorization: Bearer <token>
```

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/api/v1/auth/sms/send` | Send SMS code |
| POST | `/api/v1/auth/sms/verify` | Verify SMS code |
| POST | `/api/v1/admin/auth/login` | Admin login |
| GET | `/api/v1/users/me` | Get current user |
| PUT | `/api/v1/users/me` | Update user |
| GET | `/api/v1/posts` | List posts |
| POST | `/api/v1/posts` | Create post |
| POST | `/api/v1/posts/:id/like` | Like post |
| POST | `/api/v1/posts/:id/comments` | Add comment |
| GET | `/api/v1/search` | Search posts |
| POST | `/api/v1/upload/image` | Upload image |

## Monitoring

### Logs

Logs are written to stdout in JSON format for container environments:

```json
{
  "level": "info",
  "time": "2024-01-01T00:00:00Z",
  "msg": "request completed",
  "path": "/api/v1/posts",
  "method": "GET",
  "status": 200,
  "duration": "5.2ms"
}
```

### Metrics

Prometheus metrics available at `/metrics` (if enabled).

## Troubleshooting

### Database Connection Failed

```bash
# Check PostgreSQL status
docker-compose logs postgres

# Verify connection
docker-compose exec postgres psql -U aliang -d aliang
```

### Redis Connection Failed

```bash
# Check Redis status
docker-compose exec redis redis-cli ping
```

### Migration Failed

```bash
# Check migration logs
docker-compose exec backend go run cmd/migrate/main.go up -v
```

## Security Considerations

- Change all default passwords in production
- Use strong JWT secrets (32+ characters)
- Enable SSL/TLS for all connections
- Configure proper CORS origins
- Set up rate limiting (not enabled by default)
- Regular security updates for dependencies
