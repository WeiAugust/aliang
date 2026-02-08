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

require_command() {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Error: required command not found: $command_name"
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

require_command make
require_command curl
require_command open

if [[ ! -d "$IOS_PROJECT" ]]; then
    echo "Error: Xcode project not found at $IOS_PROJECT"
    exit 1
fi

echo "[1/4] Starting infrastructure containers..."
(
    cd "$REPO_ROOT"
    make dev
)

echo "[2/4] Checking backend health: $HEALTH_URL"
if is_backend_healthy; then
    echo "Backend is already running."
else
    echo "Backend is not healthy. Starting backend in background..."
    start_backend

    if wait_for_backend; then
        echo "Backend started successfully."
    else
        echo "Error: backend did not become healthy within ${WAIT_SECONDS}s."
        echo "Check logs: $BACKEND_LOG"
        if [[ -f "$BACKEND_PID_FILE" ]]; then
            echo "Backend pid file: $BACKEND_PID_FILE"
        fi
        exit 1
    fi
fi

echo "[3/4] Opening Xcode project..."
open "$IOS_PROJECT"

echo "[4/4] Ready"
echo "- Xcode Project: $IOS_PROJECT"
echo "- Scheme: AliangHostApp"
echo "- Simulator: iPhone 15+"
echo "- Run: Cmd+R"
