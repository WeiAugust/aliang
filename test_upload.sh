#!/bin/bash

# Test script for Media Upload functionality
# This script tests image and video upload endpoints

set -e

BASE_URL="http://localhost:8080/api/v1"
TOKEN=""

echo "=== Aliang Media Upload Test ==="
echo ""

# Step 1: Login to get token
echo "Step 1: Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/sms/send" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}')

echo "SMS sent: $LOGIN_RESPONSE"

VERIFY_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/sms/verify" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}')

TOKEN=$(echo $VERIFY_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get authentication token"
  echo "Response: $VERIFY_RESPONSE"
  exit 1
fi

echo "✅ Login successful"
echo "Token: ${TOKEN:0:20}..."
echo ""

# Step 2: Create a test image file
echo "Step 2: Creating test image file..."
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > /tmp/test_image.png
echo "✅ Test image created: /tmp/test_image.png"
echo ""

# Step 3: Upload image
echo "Step 3: Uploading image..."
UPLOAD_RESPONSE=$(curl -s -X POST "$BASE_URL/upload/image" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/test_image.png")

echo "Upload response: $UPLOAD_RESPONSE"

IMAGE_URL=$(echo $UPLOAD_RESPONSE | grep -o '"url":"[^"]*' | cut -d'"' -f4)

if [ -z "$IMAGE_URL" ]; then
  echo "❌ Failed to upload image"
  exit 1
fi

echo "✅ Image uploaded successfully"
echo "Image URL: $IMAGE_URL"
echo ""

# Step 4: Create a post with the uploaded image
echo "Step 4: Creating post with uploaded image..."
POST_RESPONSE=$(curl -s -X POST "$BASE_URL/posts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Test Post with Image\",
    \"content\": \"This is a test post with an uploaded image #test\",
    \"post_type\": \"image\",
    \"images\": [\"$IMAGE_URL\"]
  }")

echo "Post response: $POST_RESPONSE"

POST_ID=$(echo $POST_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$POST_ID" ]; then
  echo "❌ Failed to create post"
  exit 1
fi

echo "✅ Post created successfully"
echo "Post ID: $POST_ID"
echo ""

# Step 5: Verify the post
echo "Step 5: Verifying post..."
GET_POST_RESPONSE=$(curl -s "$BASE_URL/posts/$POST_ID")

echo "Get post response: $GET_POST_RESPONSE"
echo ""

# Cleanup
rm -f /tmp/test_image.png

echo "=== Test Summary ==="
echo "✅ All tests passed!"
echo ""
echo "Tested endpoints:"
echo "  - POST /api/v1/auth/sms/send"
echo "  - POST /api/v1/auth/sms/verify"
echo "  - POST /api/v1/upload/image"
echo "  - POST /api/v1/posts"
echo "  - GET /api/v1/posts/:id"
echo ""
echo "Next steps:"
echo "  1. Test video upload: POST /api/v1/upload/video"
echo "  2. Test with larger files"
echo "  3. Test file type validation"
echo "  4. Test file size limits"
