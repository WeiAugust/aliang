#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${ALIANG_API_BASE_URL:-http://localhost:8080/api/v1}"
PHONE="${ALIANG_TEST_PHONE:-13800138000}"
CODE="${ALIANG_TEST_CODE:-123456}"
TMP_IMAGE="/tmp/aliang_test_image.png"

require_command() {
    local name="$1"
    if ! command -v "$name" >/dev/null 2>&1; then
        echo "❌ 缺少命令: $name"
        exit 1
    fi
}

cleanup() {
    rm -f "$TMP_IMAGE"
}
trap cleanup EXIT

require_command curl
require_command jq
require_command base64

echo "=== Aliang 上传与发帖联调测试 ==="
echo "API: $BASE_URL"

# 1) 短信登录
curl -sS -X POST "$BASE_URL/auth/sms/send" \
  -H "Content-Type: application/json" \
  -d "{\"phone\":\"$PHONE\"}" >/tmp/aliang_send.json

TOKEN=$(curl -sS -X POST "$BASE_URL/auth/sms/verify" \
  -H "Content-Type: application/json" \
  -d "{\"phone\":\"$PHONE\",\"code\":\"$CODE\"}" | jq -r '.data.token')

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "❌ 登录失败，无法获取 token"
    cat /tmp/aliang_send.json || true
    exit 1
fi

echo "✅ 登录成功"

# 2) 生成 1x1 PNG 测试图
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==' | base64 -d > "$TMP_IMAGE"

# 3) 上传图片
UPLOAD_RESPONSE=$(curl -sS -X POST "$BASE_URL/upload/image" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@$TMP_IMAGE")

IMAGE_URL=$(echo "$UPLOAD_RESPONSE" | jq -r '.data.url')

if [[ -z "$IMAGE_URL" || "$IMAGE_URL" == "null" ]]; then
    echo "❌ 图片上传失败"
    echo "$UPLOAD_RESPONSE"
    exit 1
fi

echo "✅ 图片上传成功: $IMAGE_URL"

# 4) 用 media_urls 协议发帖
POST_RESPONSE=$(curl -sS -X POST "$BASE_URL/posts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"Upload Test\",\"content\":\"Upload flow #upload\",\"post_type\":\"image\",\"media_urls\":[\"$IMAGE_URL\"]}")

POST_ID=$(echo "$POST_RESPONSE" | jq -r '.data.id')

if [[ -z "$POST_ID" || "$POST_ID" == "null" ]]; then
    echo "❌ 发帖失败"
    echo "$POST_RESPONSE"
    exit 1
fi

echo "✅ 发帖成功: id=$POST_ID"

# 5) 验证帖子可读
GET_RESPONSE=$(curl -sS "$BASE_URL/posts/$POST_ID")
SUCCESS=$(echo "$GET_RESPONSE" | jq -r '.success')

if [[ "$SUCCESS" != "true" ]]; then
    echo "❌ 帖子读取失败"
    echo "$GET_RESPONSE"
    exit 1
fi

echo "✅ 读取帖子成功"
echo "=== 测试通过 ==="
