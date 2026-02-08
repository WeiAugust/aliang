#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"

compose_cmd() {
    if docker compose version >/dev/null 2>&1; then
        docker compose "$@"
    elif command -v docker-compose >/dev/null 2>&1; then
        docker-compose "$@"
    else
        echo "❌ 未检测到 docker compose / docker-compose"
        exit 1
    fi
}

require_command() {
    local name="$1"
    if ! command -v "$name" >/dev/null 2>&1; then
        echo "❌ 缺少命令: $name"
        exit 1
    fi
}

has_command() {
    command -v "$1" >/dev/null 2>&1
}

print_header() {
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

print_header "🚀 Aliang 一键启动"

require_command docker

if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker Desktop / Docker 服务"
    exit 1
fi

echo "✅ Docker 已就绪"

print_header "🐳 启动基础设施"
compose_cmd up -d
compose_cmd ps

echo ""
print_header "🔧 启动 Backend"

if [[ ! -f "$BACKEND_DIR/.env" && -f "$BACKEND_DIR/.env.example" ]]; then
    cp "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
    echo "✅ 已创建 backend/.env"
fi

if has_command go; then
    require_command make

    (
        cd "$BACKEND_DIR"
        go mod download
        echo "✅ Go 依赖下载完成"
        echo ""
        echo "Backend 启动中: http://localhost:8080"
        echo "按 Ctrl+C 停止"
        make dev
    )
else
    echo "⚠️ 未检测到 Go，跳过 Backend 启动"
    echo ""
    echo "后续手动执行："
    echo "  cd backend && go mod download && make dev"
    echo ""
    echo "Admin 启动命令："
    echo "  cd admin && npm ci && npm run dev"
fi
