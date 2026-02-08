# Media Upload Testing Guide

## 🧪 Complete Testing Guide for Media Upload Feature

This guide provides step-by-step instructions for testing the newly implemented Media Upload functionality.

---

## Prerequisites

Before testing, ensure:

1. **Go is installed** (version 1.22+)
   ```bash
   brew install go
   go version
   ```

2. **Docker is running**
   ```bash
   docker --version
   docker-compose --version
   ```

3. **Infrastructure services are ready**
   ```bash
   cd /Users/weizhenguo/ai_coding_projects/aliang
   docker-compose up -d
   docker-compose ps  # All services should be healthy
   ```

---

## Test Setup

### Step 1: Start Infrastructure Services

```bash
# Start PostgreSQL, Redis, MinIO
docker-compose up -d

# Verify all services are healthy
docker-compose ps

# Expected output:
# aliang-postgres  healthy
# aliang-redis     healthy
# aliang-minio     healthy

# Check MinIO is accessible
curl http://localhost:9000/minio/health/live
# Expected: OK
```

### Step 2: Configure Backend

```bash
cd backend

# Copy environment file if not exists
cp .env.example .env

# Verify configuration
cat .env | grep MINIO
# Should show:
# MINIO_ENDPOINT=localhost:9000
# MINIO_ACCESS_KEY=minioadmin
# MINIO_SECRET_KEY=minioadmin123
# MINIO_USE_SSL=false
# MINIO_BUCKET=aliang-media
```

### Step 3: Install Dependencies

```bash
cd backend

# Download Go dependencies
go mod download

# Verify dependencies
go mod tidy

# Should complete without errors
```

### Step 4: Start Backend Server

```bash
cd backend

# Run the API server
go run cmd/api/main.go

# Expected output:
# {"level":"info","msg":"Starting server","address":"0.0.0.0:8080"}
```

---

## Manual Testing

### Test 1: Health Check

```bash
curl http://localhost:8080/health

# Expected response:
# {"status":"healthy"}
```

### Test 2: Authentication

```bash
# Send SMS verification code
curl -X POST http://localhost:8080/api/v1/auth/sms/send \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'

# Expected response:
# {"success":true,"data":{"code":"123456",...}}

# Verify code and login
curl -X POST http://localhost:8080/api/v1/auth/sms/verify \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}'

# Expected response:
# {"success":true,"data":{"token":"eyJ...","user":{...}}}

# Save the token for subsequent requests
export TOKEN="<token-from-response>"
```

### Test 3: Upload Image

```bash
# Create a test image
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > /tmp/test.png

# Upload the image
curl -X POST http://localhost:8080/api/v1/upload/image \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/test.png"

# Expected response:
# {
#   "success": true,
#   "data": {
#     "url": "http://localhost:9000/aliang-media/images/1234567890_test.png",
#     "thumbnail_url": "http://localhost:9000/aliang-media/images/1234567890_test.png"
#   }
# }

# Save the image URL
export IMAGE_URL="<url-from-response>"
```

### Test 4: Verify Image in MinIO

```bash
# Access MinIO console
open http://localhost:9001

# Login credentials:
# Username: minioadmin
# Password: minioadmin123

# Navigate to: Buckets > aliang-media > images
# You should see the uploaded image file
```

### Test 5: Create Post with Uploaded Image

```bash
# Create a post using the uploaded image URL
curl -X POST http://localhost:8080/api/v1/posts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Test Post with Image\",
    \"content\": \"This is a test post with an uploaded image #test\",
    \"post_type\": \"image\",
    \"images\": [\"$IMAGE_URL\"]
  }"

# Expected response:
# {
#   "success": true,
#   "data": {
#     "id": 1,
#     "title": "Test Post with Image",
#     "images": ["http://localhost:9000/aliang-media/images/..."],
#     ...
#   }
# }

# Save the post ID
export POST_ID="<id-from-response>"
```

### Test 6: Verify Post with Image

```bash
# Get the post
curl http://localhost:8080/api/v1/posts/$POST_ID

# Expected response should include the image URL in the images array
```

### Test 7: Upload Video

```bash
# Create a test video file (small MP4)
# For testing, create a minimal valid MP4 file
dd if=/dev/zero of=/tmp/test.mp4 bs=1024 count=100

# Upload the video
curl -X POST http://localhost:8080/api/v1/upload/video \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/test.mp4"

# Expected response:
# {
#   "success": true,
#   "data": {
#     "url": "http://localhost:9000/aliang-media/videos/1234567890_test.mp4",
#     "thumbnail_url": ""
#   }
# }
```

### Test 8: Error Cases

**Test invalid file type:**
```bash
# Create a text file
echo "This is not an image" > /tmp/test.txt

# Try to upload as image
curl -X POST http://localhost:8080/api/v1/upload/image \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/test.txt"

# Expected response:
# {
#   "success": false,
#   "error": {
#     "code": "VALIDATION_ERROR",
#     "message": "Invalid file type. Only images are allowed (jpg, jpeg, png, gif, webp)"
#   }
# }
```

**Test without authentication:**
```bash
curl -X POST http://localhost:8080/api/v1/upload/image \
  -F "file=@/tmp/test.png"

# Expected response:
# {
#   "success": false,
#   "error": {
#     "code": "UNAUTHORIZED",
#     "message": "Missing or invalid token"
#   }
# }
```

**Test file size limit:**
```bash
# Create a large file (>10MB for images)
dd if=/dev/zero of=/tmp/large.jpg bs=1M count=11

# Try to upload
curl -X POST http://localhost:8080/api/v1/upload/image \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/large.jpg"

# Expected response:
# {
#   "success": false,
#   "error": {
#     "code": "VALIDATION_ERROR",
#     "message": "File size exceeds 10MB limit"
#   }
# }
```

---

## Automated Testing

### Run the Test Script

```bash
# Make the script executable
chmod +x test_upload.sh

# Run the automated test
./test_upload.sh

# Expected output:
# === Aliang Media Upload Test ===
# Step 1: Logging in...
# ✅ Login successful
# Step 2: Creating test image file...
# ✅ Test image created
# Step 3: Uploading image...
# ✅ Image uploaded successfully
# Step 4: Creating post with uploaded image...
# ✅ Post created successfully
# Step 5: Verifying post...
# === Test Summary ===
# ✅ All tests passed!
```

### Run Unit Tests

```bash
cd backend

# Run all tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run tests for specific packages
go test ./internal/service/...
go test ./internal/handler/...

# Generate coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html
open coverage.html
```

---

## Integration Testing

### Test Complete Upload Workflow

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/sms/verify \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}' | jq -r '.data.token')

echo "Token: $TOKEN"

# 2. Upload multiple images
IMAGE1=$(curl -s -X POST http://localhost:8080/api/v1/upload/image \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/test1.png" | jq -r '.data.url')

IMAGE2=$(curl -s -X POST http://localhost:8080/api/v1/upload/image \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/test2.png" | jq -r '.data.url')

echo "Image 1: $IMAGE1"
echo "Image 2: $IMAGE2"

# 3. Create post with multiple images
POST=$(curl -s -X POST http://localhost:8080/api/v1/posts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Multi-Image Post\",
    \"content\": \"Post with multiple images #test #photos\",
    \"post_type\": \"image\",
    \"images\": [\"$IMAGE1\", \"$IMAGE2\"]
  }")

echo "Post created: $POST"

# 4. Verify post
POST_ID=$(echo $POST | jq -r '.data.id')
curl -s http://localhost:8080/api/v1/posts/$POST_ID | jq '.'
```

---

## Performance Testing

### Test Concurrent Uploads

```bash
# Create test script for concurrent uploads
cat > /tmp/concurrent_upload.sh << 'EOF'
#!/bin/bash
TOKEN=$1
for i in {1..10}; do
  curl -X POST http://localhost:8080/api/v1/upload/image \
    -H "Authorization: Bearer $TOKEN" \
    -F "file=@/tmp/test.png" &
done
wait
EOF

chmod +x /tmp/concurrent_upload.sh

# Run concurrent uploads
/tmp/concurrent_upload.sh "$TOKEN"
```

### Test Large File Upload

```bash
# Create a 9MB test file (just under the 10MB limit)
dd if=/dev/zero of=/tmp/large_test.jpg bs=1M count=9

# Upload
time curl -X POST http://localhost:8080/api/v1/upload/image \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/large_test.jpg"

# Monitor upload time and success
```

---

## Troubleshooting

### Issue: Backend won't start

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
```

### Issue: Upload fails with connection error

```bash
# Check MinIO is accessible
curl http://localhost:9000/minio/health/live

# Check MinIO credentials in .env
cat backend/.env | grep MINIO

# Test MinIO connection
docker-compose exec minio mc alias set local http://localhost:9000 minioadmin minioadmin123
docker-compose exec minio mc ls local/
```

### Issue: File not found in MinIO

```bash
# Check if bucket exists
docker-compose exec minio mc ls local/

# Create bucket if missing
docker-compose exec minio mc mb local/aliang-media

# Set bucket policy to public (for testing)
docker-compose exec minio mc anonymous set download local/aliang-media
```

### Issue: Authentication fails

```bash
# Verify SMS mock is enabled
cat backend/.env | grep SMS_MOCK

# Should show:
# SMS_MOCK_ENABLED=true
# SMS_MOCK_CODE=123456

# Test authentication flow
curl -X POST http://localhost:8080/api/v1/auth/sms/send \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'

curl -X POST http://localhost:8080/api/v1/auth/sms/verify \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}'
```

---

## Test Checklist

### Functional Tests
- [ ] Health check endpoint works
- [ ] Authentication flow works
- [ ] Image upload succeeds
- [ ] Video upload succeeds
- [ ] Uploaded files accessible in MinIO
- [ ] Post creation with uploaded images works
- [ ] Invalid file type rejected
- [ ] File size limit enforced
- [ ] Authentication required for uploads
- [ ] Multiple images can be uploaded

### Error Handling Tests
- [ ] Missing authentication returns 401
- [ ] Invalid file type returns 400
- [ ] File too large returns 400
- [ ] Missing file returns 400
- [ ] Network errors handled gracefully

### Integration Tests
- [ ] Complete upload workflow works
- [ ] Multiple concurrent uploads work
- [ ] Large files upload successfully
- [ ] Files persist in MinIO
- [ ] URLs are accessible

### Performance Tests
- [ ] Upload completes in reasonable time
- [ ] Concurrent uploads don't fail
- [ ] Large files don't timeout
- [ ] Memory usage is reasonable

---

## Success Criteria

✅ **All tests pass** when:
1. Backend starts without errors
2. Authentication works
3. Images upload successfully
4. Videos upload successfully
5. Files are accessible in MinIO
6. Posts can be created with uploaded media
7. Error cases are handled correctly
8. Performance is acceptable

---

## Next Steps After Testing

1. **If all tests pass:**
   - Mark Media Upload as complete ✅
   - Move to iOS client development
   - Implement thumbnail generation
   - Add image processing

2. **If tests fail:**
   - Check error messages
   - Review logs
   - Verify configuration
   - Check service health
   - Consult troubleshooting section

---

## Additional Resources

- **API Documentation**: `docs/api/README.md`
- **Implementation Summary**: `MEDIA_UPLOAD_SUMMARY.md`
- **Project Status**: `PROJECT_COMPLETE.md`
- **Next Steps**: `NEXT_STEPS.md`

---

**Testing Date:** 2026-02-08
**Status:** Ready for Testing
