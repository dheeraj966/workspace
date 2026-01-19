#!/bin/bash
# =============================================================================
# promote_app.sh - App Lifecycle Promotion
# =============================================================================
# Promotes an app from DEVELOPMENT to COMPLETED production status.
# Implements "Sequential Versioning":
#   - Finds the next available version in src/apps/completed/vN
#   - Moves the development app to that slot.
#
# Usage:
#   ./scripts/promote_app.sh <dev_app_path>
#
# Example:
#   ./scripts/promote_app.sh src/apps/development/v1
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPLETED_DIR="$PROJECT_ROOT/src/apps/completed"
REGISTRY_LOG="$PROJECT_ROOT/registry.log"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_registry() {
    local action="$1"
    local source="$2"
    local dest="$3"
    local status="$4"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] [APP_PROMOTE] [$action] [$source] [$dest] [$status]" >> "$REGISTRY_LOG"
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <dev_app_path>"
    exit 1
fi

SOURCE_PATH="$1"
ABS_SOURCE_PATH="$(cd "$(dirname "$SOURCE_PATH")" && pwd)/$(basename "$SOURCE_PATH")"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  APP PROMOTION SYSTEM${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

# Validation
if [ ! -d "$ABS_SOURCE_PATH" ]; then
    echo -e "${RED}❌ Source not found: $SOURCE_PATH${NC}"
    exit 1
fi

# Determine Next Version
mkdir -p "$COMPLETED_DIR"
NEXT_VERSION=1
while [ -d "$COMPLETED_DIR/v$NEXT_VERSION" ]; do
    ((NEXT_VERSION++))
done

TARGET_DIR="$COMPLETED_DIR/v$NEXT_VERSION"

echo "Source: $ABS_SOURCE_PATH"
echo "Target: $TARGET_DIR"
echo ""

# Confirmation
read -p "Promote this app to Release v$NEXT_VERSION? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Move
echo "🚀 Promoting..."
if mv "$ABS_SOURCE_PATH" "$TARGET_DIR"; then
    echo -e "${GREEN}✅ App successfully promoted to Release v$NEXT_VERSION${NC}"
    log_registry "PROMOTE" "$ABS_SOURCE_PATH" "$TARGET_DIR" "SUCCESS"
    
    echo ""
    echo "NOTE: Docker services pointing to the old path will need updating."
    echo "      Update docker-compose.yml to point to: src/apps/completed/v$NEXT_VERSION"
else
    echo -e "${RED}❌ Move failed${NC}"
    log_registry "PROMOTE" "$ABS_SOURCE_PATH" "$TARGET_DIR" "FAILED"
    exit 1
fi
