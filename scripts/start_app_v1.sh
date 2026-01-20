#!/bin/bash
# =============================================================================
# start_app_v1.sh - Build and Run App v1 (Ollama) Locally
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_DIR="$PROJECT_ROOT/src/apps/development/v1"
LOG_FILE="$PROJECT_ROOT/logs/app-v1.log"

# Add Local Go to PATH
export PATH="$PROJECT_ROOT/tools/go/bin:$PATH"

echo "Using Go: $(go version)"

# Kill existing instance if running
echo "Checking for existing instances..."
if pgrep -f "ollama serve" > /dev/null; then
    echo -e "\033[0;33m⚠️  Found running instance. Killing...\033[0m"
    pkill -f "ollama serve" || true
    sleep 1
fi

cd "$APP_DIR"

echo "Downloading dependencies..."
go mod download

echo "Building Ollama..."
go build -o ollama .

echo "Starting Server (Port 11434)..."
echo "Logs: $LOG_FILE"

nohup ./ollama serve > "$LOG_FILE" 2>&1 &
echo "Server PID: $!"
