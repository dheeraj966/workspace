#!/bin/bash
# =============================================================================
# snapshot.sh - Git State Snapshots
# =============================================================================
# Creates a tagged snapshot when a global success milestone is reached.
# This is called automatically by the failsafe monitor or manually by agents.
#
# Usage:
#   ./scripts/snapshot.sh [optional-tag-suffix]
#
# Examples:
#   ./scripts/snapshot.sh                  # Creates: stable-checkpoint-2026-01-18-143022
#   ./scripts/snapshot.sh research-v1      # Creates: stable-checkpoint-research-v1
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REGISTRY_LOG="$PROJECT_ROOT/registry.log"
LOGS_DIR="$PROJECT_ROOT/logs"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_registry() {
    local action="$1"
    local details="$2"
    local status="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] [SNAPSHOT] [$action] [$details] [$status]" >> "$REGISTRY_LOG"
}

echo "═══════════════════════════════════════════════════════════════"
echo "  ANTIGRAVITY STATE SNAPSHOT"
echo "═══════════════════════════════════════════════════════════════"

cd "$PROJECT_ROOT" || exit 1

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ ERROR: Not a git repository${NC}"
    exit 1
fi

# Generate tag name
if [ $# -gt 0 ]; then
    TAG_NAME="stable-checkpoint-$1"
else
    TAG_NAME="stable-checkpoint-$(date +%Y-%m-%d-%H%M%S)"
fi

# Get current commit hash
COMMIT_HASH=$(git rev-parse --short HEAD)

echo ""
echo "Tag Name:    $TAG_NAME"
echo "Commit:      $COMMIT_HASH"
echo ""

# Check if tag already exists
if git tag -l "$TAG_NAME" | grep -q .; then
    echo -e "${YELLOW}⚠️  Tag '$TAG_NAME' already exists.${NC}"
    echo "Use a different suffix or let the script auto-generate one."
    exit 1
fi

# Create the tag
echo "Creating snapshot tag..."
if git tag -a "$TAG_NAME" -m "Stable checkpoint at $(date -u +"%Y-%m-%dT%H:%M:%SZ")" 2>/dev/null; then
    echo -e "${GREEN}✅ SUCCESS: Snapshot created${NC}"
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  SNAPSHOT DETAILS"
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Tag:      $TAG_NAME"
    echo "  Commit:   $COMMIT_HASH"
    echo "  Time:     $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "To rollback to this snapshot:"
    echo "  git checkout $TAG_NAME"
    echo ""
    echo "To list all snapshots:"
    echo "  git tag -l 'stable-checkpoint-*'"
    
    log_registry "CREATE" "$TAG_NAME" "SUCCESS"
    exit 0
else
    echo -e "${RED}❌ ERROR: Failed to create tag${NC}"
    log_registry "CREATE" "$TAG_NAME" "FAILED"
    exit 1
fi
