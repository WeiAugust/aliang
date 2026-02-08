#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$REPO_ROOT/backend"
IOS_PROJECT="$SCRIPT_DIR/AliangHostApp.xcodeproj"
BACKEND_LOG="$BACKEND_DIR/.backend-dev.log"
BACKEND_PID_FILE="$BACKEND_DIR/.backend-dev.pid"
HEALTH_URL="${ALIANG_BACKEND_HEALTH_URL:-http://localhost:8080/health}"
WAIT_SECONDS="${ALIANG_BACKEND_WAIT_SECONDS:-60}"

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
    local command_name="$1"
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "❌ 缺少命令: $command_name"
        exit 1
    fi
}

is_backend_healthy() {
    curl --silent --fail "$HEALTH_URL" >/dev/null 2>&1
}

start_backend() {
    if [[ ! -f "$BACKEND_DIR/.env" && -f "$BACKEND_DIR/.env.example" ]]; then
        cp "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
    fi

    (
        cd "$BACKEND_DIR"
        nohup make dev >"$BACKEND_LOG" 2>&1 &
        echo $! >"$BACKEND_PID_FILE"
    )
}

wait_for_backend() {
    local elapsed=0

    while (( elapsed < WAIT_SECONDS )); do
        if is_backend_healthy; then
            return 0
        fi
        sleep 1
        ((elapsed += 1))
    done

    return 1
}

require_command docker
require_command curl
require_command open

if [[ ! -d "$IOS_PROJECT" ]]; then
    echo "❌ 未找到 Xcode 工程: $IOS_PROJECT"
    exit 1
fi

echo "[1/4] 启动基础设施容器..."
(
    cd "$REPO_ROOT"
    compose_cmd up -d
)

echo "[2/4] 检查后端健康: $HEALTH_URL"
if is_backend_healthy; then
    echo "✅ Backend 已在运行"
else
    if ! command -v go >/dev/null 2>&1; then
        echo "❌ Backend 未运行且本机未安装 Go，无法自动拉起后端"
        echo "请先安装 Go 后执行：cd backend && make dev"
        exit 1
    fi

    require_command make

    echo "Backend 未就绪，尝试后台启动..."
    start_backend

    if wait_for_backend; then
        echo "✅ Backend 启动成功"
    else
        echo "❌ Backend 在 ${WAIT_SECONDS}s 内未就绪"
        echo "日志: $BACKEND_LOG"
        [[ -f "$BACKEND_PID_FILE" ]] && echo "PID 文件: $BACKEND_PID_FILE"
        exit 1
    fi
fi

echo "[3/4] 打开 Xcode 工程..."
open "$IOS_PROJECT"

echo "[4/4] 就绪"
echo "- Project: $IOS_PROJECT"
echo "- Scheme: AliangHostApp"
echo "- Run: Cmd+R"
