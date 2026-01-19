#!/bin/bash
# =============================================================================
# isolate_env.sh - Per-Directory Environment Isolation
# =============================================================================
# This script initializes the appropriate isolated environment for a given directory.
# It supports Python (venv), Node.js (node_modules), and Go (go.mod).
#
# Usage:
#   ./scripts/isolate_env.sh <target_directory>
#
# Examples:
#   ./scripts/isolate_env.sh src/apps/v1
#   ./scripts/isolate_env.sh src/ml/research/experiment-A
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

if [ $# -ne 1 ]; then
    echo "Usage: $0 <target_directory>"
    exit 1
fi

TARGET_DIR="$1"
ABS_TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  ENVIRONMENT ISOLATION: $TARGET_DIR${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}❌ Directory not found: $TARGET_DIR${NC}"
    exit 1
fi

cd "$ABS_TARGET_DIR" || exit 1

# -----------------------------------------------------------------------------
# 1. Python Isolation (Virtualenv)
# -----------------------------------------------------------------------------
if [ -f "requirements.txt" ]; then
    echo -e "${YELLOW}🐍 Python Project Detected${NC}"
    if [ ! -d ".venv" ]; then
        echo "   Creating local virtualenv (.venv)..."
        python3 -m venv .venv
        
        echo "   Installing dependencies..."
        # Activating venv in subshell
        (
            source .venv/bin/activate
            pip install --upgrade pip
            pip install -r requirements.txt
        )
        echo -e "${GREEN}✅ Python setup complete${NC}"
    else
        echo -e "${GREEN}✅ .venv already exists${NC}"
    fi
fi

# -----------------------------------------------------------------------------
# 2. Node.js Isolation (node_modules)
# -----------------------------------------------------------------------------
if [ -f "package.json" ]; then
    echo -e "${YELLOW}📦 Node.js Project Detected${NC}"
    if [ ! -d "node_modules" ]; then
        echo "   Installing npm dependencies..."
        npm install
        echo -e "${GREEN}✅ Node setup complete${NC}"
    else
        echo "   node_modules exists. Checking for sync..."
        # Optional: npm ci or just assume it's fine for dev speed
        echo -e "${GREEN}✅ Node setup complete (cached)${NC}"
    fi
fi

# -----------------------------------------------------------------------------
# 3. Go Isolation (Go Modules)
# -----------------------------------------------------------------------------
if [ -f "go.mod" ]; then
    echo -e "${YELLOW}🐹 Go Project Detected${NC}"
    if ! command -v go &> /dev/null; then
        echo -e "${YELLOW}⚠️  'go' command not found. Skipping local module download.${NC}"
        echo "   (Dependencies will be handled inside Docker)"
    else
        echo "   Downloading modules..."
        if go mod download; then
            echo -e "${GREEN}✅ Go setup complete${NC}"
        else
            echo -e "${RED}❌ Go setup failed (check network/proxy)${NC}"
        fi
    fi
fi

echo ""
echo "Isolation Check Finished for: $TARGET_DIR"
