#!/bin/bash
#
# promote.sh - The Atomic Transaction Coordinator
#
# This script promotes a validated model from staging/ to stable/.
# It enforces the Three Laws of Automation.
#
# Usage:
#   ./scripts/promote.sh <model_id>
#
# Example:
#   ./scripts/promote.sh transformer-v1.0.0
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
STAGING_DIR="$PROJECT_ROOT/models/staging"
STABLE_DIR="$PROJECT_ROOT/models/stable"
REGISTRY_LOG="$PROJECT_ROOT/registry.log"
VALIDATOR="$SCRIPT_DIR/validate_model.py"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_registry() {
    local action="$1"
    local model_id="$2"
    local source="$3"
    local destination="$4"
    local status="$5"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] [$action] [$model_id] [$source] [$destination] [$status]" >> "$REGISTRY_LOG"
}

echo "═══════════════════════════════════════════════════════════════"
echo "  ANTIGRAVITY MODEL PROMOTION - Atomic Transaction Coordinator"
echo "═══════════════════════════════════════════════════════════════"

# Validate arguments
if [ $# -ne 1 ]; then
    echo -e "${RED}Usage: ./scripts/promote.sh <model_id>${NC}"
    echo "Example: ./scripts/promote.sh transformer-v1.0.0"
    exit 1
fi

MODEL_ID="$1"
SOURCE_PATH="$STAGING_DIR/$MODEL_ID"
DEST_PATH="$STABLE_DIR/$MODEL_ID"

echo ""
echo "Model ID:    $MODEL_ID"
echo "Source:      $SOURCE_PATH"
echo "Destination: $DEST_PATH"
echo ""

# ═══════════════════════════════════════════════════════════════════
# LAW 1: Check source exists in staging
# ═══════════════════════════════════════════════════════════════════
echo "🔍 Checking source path..."
if [ ! -d "$SOURCE_PATH" ]; then
    echo -e "${RED}❌ ABORT: Model '$MODEL_ID' not found in staging/${NC}"
    log_registry "PROMOTE" "$MODEL_ID" "$SOURCE_PATH" "$DEST_PATH" "FAILED:SOURCE_NOT_FOUND"
    exit 1
fi
echo -e "${GREEN}✅ Source exists${NC}"

# ═══════════════════════════════════════════════════════════════════
# LAW 2: Law of Immutability - Check destination doesn't exist
# ═══════════════════════════════════════════════════════════════════
echo "🔍 Checking for existing version in stable/..."
if [ -d "$DEST_PATH" ]; then
    echo -e "${RED}❌ ABORT: Model '$MODEL_ID' already exists in stable/${NC}"
    echo -e "${YELLOW}   The Law of Immutability prevents overwriting.${NC}"
    echo -e "${YELLOW}   To update, create a new version (e.g., v1.0.0 → v1.0.1)${NC}"
    log_registry "PROMOTE" "$MODEL_ID" "$SOURCE_PATH" "$DEST_PATH" "FAILED:ALREADY_EXISTS"
    exit 1
fi
echo -e "${GREEN}✅ No existing version found${NC}"

# ═══════════════════════════════════════════════════════════════════
# LAW 3: Run Tier-1 Gatekeeper validation
# ═══════════════════════════════════════════════════════════════════
echo ""
echo "🛡️  Running Tier-1 Gatekeeper validation..."
echo ""

if ! python3 "$VALIDATOR" "$SOURCE_PATH"; then
    echo ""
    echo -e "${RED}❌ ABORT: Validation failed. Promotion cancelled.${NC}"
    log_registry "PROMOTE" "$MODEL_ID" "$SOURCE_PATH" "$DEST_PATH" "FAILED:VALIDATION"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════
# ATOMIC PROMOTION: Use mv for atomic operation
# ═══════════════════════════════════════════════════════════════════
echo ""
echo "🚀 Executing atomic promotion..."

if mv "$SOURCE_PATH" "$DEST_PATH"; then
    echo -e "${GREEN}✅ SUCCESS: Model '$MODEL_ID' promoted to stable/${NC}"
    log_registry "PROMOTE" "$MODEL_ID" "$SOURCE_PATH" "$DEST_PATH" "SUCCESS"
    
    # Print summary
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  PROMOTION COMPLETE"
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Model:       $MODEL_ID"
    echo "  Location:    $DEST_PATH"
    echo "  Registry:    Entry added to registry.log"
    echo "═══════════════════════════════════════════════════════════════"
    exit 0
else
    echo -e "${RED}❌ FATAL: Move operation failed${NC}"
    log_registry "PROMOTE" "$MODEL_ID" "$SOURCE_PATH" "$DEST_PATH" "FAILED:MOVE_ERROR"
    exit 1
fi
