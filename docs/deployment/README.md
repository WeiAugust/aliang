# Deployment Guide

## Overview

This guide covers deploying the Aliang community content system to production. The system consists of three main components:

1. **Backend API** (Go)
2. **Admin Panel** (React)
3. **Infrastructure** (PostgreSQL, Redis, MinIO)

## Prerequisites

### Server Requirements

**Minimum**:
- 2 vCPU
- 4 GB RAM
- 40 GB SSD storage
- Ubuntu 22.04 LTS or later

**Recommended**:
- 4 vCPU
- 8 GB RAM
- 100 GB SSD storage
- Ubuntu 22.04 LTS

### Software Requirements

- Docker 24.0+
- Docker Compose v2.20+
- Git
- Domain name with DNS configured
- SSL certificate (Let's Encrypt recommended)

## Initial Server Setup

### 1. Update System

```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Verify installation
docker --version
docker compose version
```

### 3. Configure Firewall

```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

### 4. Create Deployment User

```bash
# Create user
sudo adduser deploy

# Add to docker group
sudo usermod -aG docker deploy

# Switch to deploy user
su - deploy
```

## Clone Repository

```bash
cd ~
git clone https://github.com/WeiAugust/aliang.git
cd aliang
```

## Configuration

### 1. Environment Variables

Create production environment file:

```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env`:

```bash
# Database
DB_HOST=postgres
DB_PORT=5432
DB_USER=aliang
DB_PASSWORD=CHANGE_ME_STRONG_PASSWORD
DB_NAME=aliang
DB_SSL_MODE=require

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=CHANGE_ME_REDIS_PASSWORD

# MinIO
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=CHANGE_ME_ACCESS_KEY
MINIO_SECRET_KEY=CHANGE_ME_SECRET_KEY
MINIO_USE_SSL=false
MINIO_BUCKET=aliang-media

# Server
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
JWT_SECRET=CHANGE_ME_LONG_RANDOM_STRING
JWT_EXPIRY=24h

# Admin
ADMIN_USERNAME=admin
ADMIN_PASSWORD=CHANGE_ME_ADMIN_PASSWORD

# SMS Mock (disable in production)
SMS_MOCK_ENABLED=false

# File Upload
UPLOAD_MAX_SIZE=10485760
UPLOAD_ALLOWED_IMAGES=jpg,jpeg,png,webp
UPLOAD_ALLOWED_VIDEOS=mp4

# CORS
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://admin.yourdomain.com
```

**Important**: Replace all `CHANGE_ME_*` values with strong, randomly generated passwords.

### 2. Generate Secrets

```bash
# Generate JWT secret (256-bit)
openssl rand -hex 32

# Generate database password
openssl rand -base64 32

# Generate Redis password
openssl rand -base64 32

# Generate MinIO credentials
openssl rand -base64 20
```

### 3. Admin Panel Configuration

Create admin environment file:

```bash
cp admin/.env.example admin/.env
```

Edit `admin/.env`:

```bash
VITE_API_BASE_URL=https://api.yourdomain.com/api/v1
```

## Docker Compose Production Configuration

Create `docker-compose.prod.yml`:

```yaml
version: '3.9'

services:
  postgres:
    image: postgres:16-alpine
    container_name: aliang-postgres
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - aliang-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G

  redis:
    image: redis:7-alpine
    container_name: aliang-redis
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis-data:/data
    networks:
      - aliang-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  minio:
    image: minio/minio:latest
    container_name: aliang-minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ACCESS_KEY}
      MINIO_ROOT_PASSWORD: ${MINIO_SECRET_KEY}
    volumes:
      - minio-data:/data
    networks:
      - aliang-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: aliang-backend
    env_file:
      - backend/.env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      minio:
        condition: service_healthy
    networks:
      - aliang-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G

  admin:
    build:
      context: ./admin
      dockerfile: Dockerfile
      args:
        VITE_API_BASE_URL: ${VITE_API_BASE_URL}
    container_name: aliang-admin
    networks:
      - aliang-network
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  nginx:
    image: nginx:alpine
    container_name: aliang-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/logs:/var/log/nginx
    depends_on:
      - backend
      - admin
    networks:
      - aliang-network
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M

volumes:
  postgres-data:
    driver: local
  redis-data:
    driver: local
  minio-data:
    driver: local

networks:
  aliang-network:
    driver: bridge
```

## Nginx Configuration

Create `nginx/nginx.conf`:

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss
               application/rss+xml font/truetype font/opentype
               application/vnd.ms-fontobject image/svg+xml;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/m;
    limit_req_zone $binary_remote_addr zone=auth_limit:10m rate=10r/m;

    # Backend API
    upstream backend {
        server backend:8080;
    }

    # Admin Panel
    upstream admin {
        server admin:80;
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name yourdomain.com api.yourdomain.com admin.yourdomain.com;
        return 301 https://$server_name$request_uri;
    }

    # Backend API
    server {
        listen 443 ssl http2;
        server_name api.yourdomain.com;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # API endpoints
        location /api/ {
            limit_req zone=api_limit burst=20 nodelay;

            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;

            # File upload
            client_max_body_size 100M;
        }

        # Auth endpoints (stricter rate limit)
        location /api/v1/auth/ {
            limit_req zone=auth_limit burst=5 nodelay;

            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check
        location /health {
            proxy_pass http://backend;
            access_log off;
        }
    }

    # Admin Panel
    server {
        listen 443 ssl http2;
        server_name admin.yourdomain.com;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        root /usr/share/nginx/html;
        index index.html;

        # SPA routing
        location / {
            try_files $uri $uri/ /index.html;
        }

        # Static assets caching
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # HTML no-cache
        location ~* \.html$ {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }
}
```

## SSL Certificate Setup

### Using Let's Encrypt (Recommended)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain certificate
sudo certbot certonly --standalone -d yourdomain.com -d api.yourdomain.com -d admin.yourdomain.com

# Copy certificates
sudo mkdir -p nginx/ssl
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem nginx/ssl/

# Set permissions
sudo chown -R deploy:deploy nginx/ssl
```

### Auto-renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Add cron job for auto-renewal
sudo crontab -e

# Add this line:
0 0 * * * certbot renew --quiet && docker compose -f /home/deploy/aliang/docker-compose.prod.yml restart nginx
```

## Database Migration

```bash
# Run migrations
docker compose -f docker-compose.prod.yml run --rm backend /app/migrate up
```

## First Deployment

### 1. Build Images

```bash
docker compose -f docker-compose.prod.yml build
```

### 2. Start Services

```bash
docker compose -f docker-compose.prod.yml up -d
```

### 3. Verify Services

```bash
# Check all services are running
docker compose -f docker-compose.prod.yml ps

# Check logs
docker compose -f docker-compose.prod.yml logs -f

# Test backend health
curl https://api.yourdomain.com/health

# Test admin panel
curl https://admin.yourdomain.com
```

### 4. Create Admin Account

The admin account is created automatically with credentials from `.env`:
- Username: Value of `ADMIN_USERNAME`
- Password: Value of `ADMIN_PASSWORD`

## Updating the Application

### 1. Pull Latest Code

```bash
cd ~/aliang
git pull origin main
```

### 2. Rebuild Images

```bash
docker compose -f docker-compose.prod.yml build
```

### 3. Run Migrations

```bash
docker compose -f docker-compose.prod.yml run --rm backend /app/migrate up
```

### 4. Restart Services

```bash
docker compose -f docker-compose.prod.yml up -d
```

### 5. Verify Update

```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f backend
```

## Rollback

If an update causes issues:

```bash
# Stop services
docker compose -f docker-compose.prod.yml down

# Checkout previous version
git checkout <previous-commit-hash>

# Rebuild and restart
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d

# Rollback migrations if needed
docker compose -f docker-compose.prod.yml run --rm backend /app/migrate down
```

## Backup and Restore

### Database Backup

```bash
# Create backup
docker compose -f docker-compose.prod.yml exec postgres pg_dump -U aliang aliang > backup_$(date +%Y%m%d_%H%M%S).sql

# Automated daily backups
crontab -e

# Add this line:
0 2 * * * cd /home/deploy/aliang && docker compose -f docker-compose.prod.yml exec -T postgres pg_dump -U aliang aliang > /home/deploy/backups/aliang_$(date +\%Y\%m\%d).sql
```

### Database Restore

```bash
# Restore from backup
docker compose -f docker-compose.prod.yml exec -T postgres psql -U aliang aliang < backup_20240101_120000.sql
```

### Media Files Backup

```bash
# Backup MinIO data
docker compose -f docker-compose.prod.yml exec minio mc mirror /data /backup

# Or use volume backup
docker run --rm -v aliang_minio-data:/data -v $(pwd)/backup:/backup alpine tar czf /backup/minio-backup.tar.gz -C /data .
```

## Monitoring

### View Logs

```bash
# All services
docker compose -f docker-compose.prod.yml logs -f

# Specific service
docker compose -f docker-compose.prod.yml logs -f backend

# Last 100 lines
docker compose -f docker-compose.prod.yml logs --tail=100 backend
```

### Resource Usage

```bash
# Container stats
docker stats

# Disk usage
docker system df
```

### Health Checks

```bash
# Backend health
curl https://api.yourdomain.com/health

# Database connection
docker compose -f docker-compose.prod.yml exec postgres pg_isready -U aliang

# Redis connection
docker compose -f docker-compose.prod.yml exec redis redis-cli ping
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker compose -f docker-compose.prod.yml logs <service-name>

# Check configuration
docker compose -f docker-compose.prod.yml config

# Restart service
docker compose -f docker-compose.prod.yml restart <service-name>
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker compose -f docker-compose.prod.yml ps postgres

# Check connection from backend
docker compose -f docker-compose.prod.yml exec backend ping postgres

# Check credentials
docker compose -f docker-compose.prod.yml exec postgres psql -U aliang -d aliang
```

### High Memory Usage

```bash
# Check container memory
docker stats

# Restart services
docker compose -f docker-compose.prod.yml restart

# Adjust resource limits in docker-compose.prod.yml
```

### Disk Space Issues

```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a

# Remove old images
docker image prune -a

# Remove old logs
sudo truncate -s 0 /var/lib/docker/containers/*/*-json.log
```

## Security Best Practices

1. **Keep Software Updated**
   ```bash
   sudo apt update && sudo apt upgrade -y
   docker compose -f docker-compose.prod.yml pull
   ```

2. **Use Strong Passwords**
   - Generate random passwords for all services
   - Store passwords securely (e.g., password manager)

3. **Enable Firewall**
   ```bash
   sudo ufw enable
   sudo ufw status
   ```

4. **Regular Backups**
   - Automate daily database backups
   - Store backups off-site

5. **Monitor Logs**
   - Set up log aggregation
   - Configure alerts for errors

6. **SSL/TLS**
   - Use Let's Encrypt for free SSL certificates
   - Enable HSTS headers

7. **Rate Limiting**
   - Configure Nginx rate limiting
   - Monitor for abuse

## Performance Optimization

### Database

```sql
-- Create indexes
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_likes_post_id ON likes(post_id);
CREATE INDEX idx_likes_user_post ON likes(user_id, post_id);

-- Analyze tables
ANALYZE posts;
ANALYZE users;
ANALYZE comments;
ANALYZE likes;
```

### Redis

```bash
# Configure persistence
docker compose -f docker-compose.prod.yml exec redis redis-cli CONFIG SET save "900 1 300 10 60 10000"

# Set max memory
docker compose -f docker-compose.prod.yml exec redis redis-cli CONFIG SET maxmemory 512mb
docker compose -f docker-compose.prod.yml exec redis redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

### Nginx

- Enable gzip compression (already configured)
- Use HTTP/2 (already configured)
- Configure caching headers (already configured)

## Support

For issues or questions:
- GitHub Issues: https://github.com/WeiAugust/aliang/issues
- Documentation: https://github.com/WeiAugust/aliang/tree/main/docs
