#!/bin/bash
# =============================================================================
# start_app_v2.sh - Build and Run Open WebUI (App v2)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_DIR="$PROJECT_ROOT/src/apps/development/v2"
BACKEND_DIR="$APP_DIR/backend"
CONDA_PATH="$PROJECT_ROOT/tools/miniconda"
LOG_FILE="$PROJECT_ROOT/logs/app-v2.log"

# Define cleanup function
cleanup() {
    echo "Stopping App v2..."
    pkill -P $$ || true
}
trap cleanup EXIT INT TERM

echo "🚀 Starting App v2 (Open WebUI)..."

# 1. Activate Conda Environment
echo "🐍 Activating Python 3.11 (app-v2)..."
source "$CONDA_PATH/bin/activate" app-v2

# 2. Frontend Build (One-time or Update)
cd "$APP_DIR"
if [ ! -d "build" ] && [ ! -d "dist" ]; then
    echo "📦 Installing Frontend Dependencies..."
    npm install --legacy-peer-deps
    
    echo "🏗️  Building Frontend..."
    npm run build
fi

# Determine build output storage
BUILD_DIR="build"
if [ -d "dist" ]; then BUILD_DIR="dist"; fi

# 3. Integrate Frontend with Backend
# Copy build artifacts to where backend expects them (emulating pip install structure)
# Based on pyproject.toml: build -> open_webui/frontend
TARGET_FRONTEND="$BACKEND_DIR/open_webui/frontend"
if [ -d "$BUILD_DIR" ]; then
    echo "🔗 Linking Frontend to Backend..."
    rm -rf "$TARGET_FRONTEND"
    mkdir -p "$TARGET_FRONTEND"
    cp -r "$BUILD_DIR"/* "$TARGET_FRONTEND"/
fi

# 4. Backend Dependencies
cd "$BACKEND_DIR"
echo "📥 Installing Backend Dependencies..."
pip install -r requirements.txt > /dev/null

# 5. Start Server
echo "🟢 Starting Server on Port 8080..."
echo "Logs: $LOG_FILE"

# Set Env Vars
export OLLAMA_BASE_URL="http://127.0.0.1:11434"
export WEBUI_AUTH=false # Optional: disable auth for local dev convenience? Keeping default true.
export PORT=8080

# Run using the start.sh which handles uvicorn
# We run it in foreground to keep script alive, or use exec
# But we trap signals, so let's run it direct.
# Actually start.sh runs in BG if we are not careful? No, it uses exec.

./start.sh > "$LOG_FILE" 2>&1 &
SERVER_PID=$!
echo "Server PID: $SERVER_PID"

wait $SERVER_PID
