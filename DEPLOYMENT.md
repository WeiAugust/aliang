# Aliang Deployment Guide

This guide covers two deployment methods for the Aliang platform:
1. **Docker Compose** (recommended for most users)
2. **Manual Compilation** (for custom deployments)

## Prerequisites

| Component | Minimum Version |
|-----------|----------------|
| Docker | 24+ |
| Docker Compose | v2 |
| PostgreSQL | 16 (if manual) |
| Redis | 7 (if manual) |
| Go | 1.22+ (if manual) |
| Node.js | 20+ (if manual) |

---

## Method 1: Docker Compose (Recommended)

### Step 1: Clone the Repository

```bash
git clone https://github.com/WeiAugust/aliang.git
cd aliang
```

### Step 2: Start Infrastructure Services

```bash
# Start PostgreSQL, Redis, and MinIO
docker-compose up -d
```

**Services started:**
| Service | URL | Credentials |
|---------|-----|-------------|
| PostgreSQL | localhost:5432 | `aliang` / `aliang123` |
| Redis | localhost:6379 | No auth |
| MinIO API | localhost:9000 | `minioadmin` / `minioadmin123` |
| MinIO Console | localhost:9001 | `minioadmin` / `minioadmin123` |

### Step 3: Run Database Migrations

```bash
cd backend
docker run --rm \
  -e DATABASE_URL=postgres://aliang:aliang123@localhost:5432/aliang?sslmode=disable \
  -v $(pwd)/migrations:/migrations \
  migrate/migrate:latest \
  -path /migrations -database "postgres://aliang:aliang123@localhost:5432/aliang?sslmode=disable" up
```

Or if you have Go installed locally:

```bash
cd backend
make migrate-up
```

### Step 4: Start All Services

#### Option A: Use Docker Compose (Full Stack)

```bash
# Build and start all services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

#### Option B: Start Services Individually

**Backend API:**
```bash
docker run -d \
  --name aliang-backend \
  -p 8080:8080 \
  -e DATABASE_URL=postgres://aliang:aliang123@host.docker.internal:5432/aliang?sslmode=disable \
  -e REDIS_URL=redis://host.docker.internal:6379 \
  -e MINIO_ENDPOINT=host.docker.internal:9000 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin123 \
  ghcr.io/weiaugust/aliang/backend:latest
```

**Admin Panel:**
```bash
docker run -d \
  --name aliang-admin \
  -p 80:80 \
  ghcr.io/weiaugust/aliang/admin:latest
```

### Step 5: Verify Deployment

```bash
# Check service health
curl http://localhost:8080/health

# Access admin panel
open http://localhost
```

---

## Method 2: Manual Compilation

### Step 1: Clone the Repository

```bash
git clone https://github.com/WeiAugust/aliang.git
cd aliang
```

### Step 2: Set Up Infrastructure

**Using Docker for infrastructure only:**

```bash
docker-compose up -d postgres redis minio
```

**Or install locally:**
- PostgreSQL 16: Download from [postgresql.org](https://www.postgresql.org/download/)
- Redis 7: Download from [redis.io](https://redis.io/download/)
- MinIO: Download from [min.io](https://min.io/download)

### Step 3: Configure Environment

**Backend (.env):**
```bash
cd backend
cp .env.example .env
# Edit .env with your configuration
```

```env
# Server
PORT=8080
ENV=production

# Database
DATABASE_URL=postgres://aliang:aliang123@localhost:5432/aliang?sslmode=disable

# Redis
REDIS_URL=redis://localhost:6379

# JWT
JWT_SECRET=your-secret-key-here

# MinIO/S3
MINIO_ENDPOINT=localhost:9000
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin123
MINIO_USE_SSL=false
```

**Admin Panel (.env):**
```bash
cd admin
cp .env.example .env
```

```env
VITE_API_BASE_URL=http://localhost:8080/api/v1
```

### Step 4: Build and Run Backend

```bash
cd backend

# Install dependencies
go mod download

# Run database migrations
make migrate-up

# Build
make build

# Run
./bin/api
```

### Step 5: Build and Run Admin Panel

```bash
cd admin

# Install dependencies
npm ci

# Build for production
npm run build

# Serve with nginx or any static file server
npx serve -s dist -l 3000
```

### Step 6: Start iOS App (macOS only)

```bash
cd ios
./start_ios.sh
```

Or build for simulator:

```bash
cd ios
xcodebuild -scheme AliangHostApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

---

## Configuration Reference

### Environment Variables

#### Backend

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PORT` | No | 8080 | Server port |
| `ENV` | No | development | Environment mode |
| `DATABASE_URL` | Yes | - | PostgreSQL connection string |
| `REDIS_URL` | No | redis://localhost:6379 | Redis connection string |
| `JWT_SECRET` | Yes | - | JWT signing key |
| `JWT_EXPIRY` | No | 24h | Token expiry time |
| `MINIO_ENDPOINT` | No | localhost:9000 | MinIO API endpoint |
| `MINIO_ROOT_USER` | No | minioadmin | MinIO root user |
| `MINIO_ROOT_PASSWORD` | No | minioadmin123 | MinIO root password |
| `MINIO_BUCKET` | No | aliang-media | Media bucket name |

#### Admin Panel

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `VITE_API_BASE_URL` | No | http://localhost:8080/api/v1 | Backend API base URL |

---

## Test Accounts

After deployment, use these credentials to test the platform:

### Admin Panel

| Field | Value |
|-------|-------|
| URL | http://localhost:3000 (development) or http://localhost (production) |
| Username | `admin` |
| Password | `admin123` |

### Mobile App (Development)

| Field | Value |
|-------|-------|
| Phone | `13800138000` |
| Verification Code | `123456` |

---

## Production Checklist

- [ ] Change all default passwords
- [ ] Enable SSL/TLS for all services
- [ ] Set up database backups
- [ ] Configure log aggregation
- [ ] Set up monitoring and alerting
- [ ] Use managed PostgreSQL (Cloud SQL, RDS, etc.)
- [ ] Use managed Redis (ElastiCache, Memorystore, etc.)
- [ ] Use managed object storage (S3, GCS, etc.)
- [ ] Set up firewall rules
- [ ] Configure rate limiting
- [ ] Set up CDN for static assets

---

## Troubleshooting

### Database Connection Failed

```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Test connection
psql -h localhost -U aliang -d aliang
```

### Redis Connection Failed

```bash
# Check Redis is running
docker ps | grep redis

# Test connection
redis-cli ping
```

### MinIO Bucket Not Found

```bash
# Create bucket via mc (MinIO Client)
mc alias set myminio http://localhost:9000 minioadmin minioadmin123
mc mb myminio/aliang-media
```

### Backend Health Check Fails

```bash
# Check backend logs
docker logs aliang-backend

# Check environment variables
docker exec aliang-backend env | grep -E 'DATABASE|REDIS|MINIO'
```

### Admin Panel Shows 502

```bash
# Check nginx logs
docker logs aliang-admin

# Verify backend is running
curl http://localhost:8080/health
```

---

## Support

- GitHub Issues: https://github.com/WeiAugust/aliang/issues
- Documentation: https://github.com/WeiAugust/aliang/tree/main/docs
