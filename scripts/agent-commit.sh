#!/bin/bash
# =============================================================================
# agent-commit.sh - Atomic Commits with Directory Scoping
# =============================================================================
# This script enforces the Rules for Parallel Agents:
# 1. Atomic Commits: Only commit when local validator passes
# 2. Directory Scoping: Agents can only commit their designated directories
# 3. Ledger Locking: Respects registry.log as a file-lock
#
# Usage:
#   ./scripts/agent-commit.sh <agent-type> <message>
#
# Agent Types:
#   research  - Can only commit src/ml/research/
#   redesign  - Can only commit src/ml/redesign/
#   app       - Can only commit src/ (excluding src/ml/)
#
# Examples:
#   ./scripts/agent-commit.sh research "Add attention experiment"
#   ./scripts/agent-commit.sh redesign "Optimize layer normalization"
#   ./scripts/agent-commit.sh app "Add API endpoint for inference"
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REGISTRY_LOG="$PROJECT_ROOT/registry.log"
LOGS_DIR="$PROJECT_ROOT/logs"
VALIDATOR="$SCRIPT_DIR/validate_model.py"

# Agent-to-directory mapping (scoping rules)
declare -A AGENT_DIRS=(
    ["research"]="src/ml/research"
    ["redesign"]="src/ml/redesign"
    ["app"]="src"
)

# Directories that app agent cannot touch
APP_EXCLUDED_DIRS=("src/ml/research" "src/ml/redesign")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_registry() {
    local action="$1"
    local agent="$2"
    local status="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] [COMMIT] [$action] [$agent] [$status]" >> "$REGISTRY_LOG"
}

# =============================================================================
# Validation Functions
# =============================================================================

check_ledger_lock() {
    # Check if a promotion is in progress
    if grep -q "Promotion in Progress" "$REGISTRY_LOG" 2>/dev/null; then
        local last_lock=$(grep "Promotion in Progress" "$REGISTRY_LOG" | tail -1)
        echo -e "${YELLOW}⚠️  Ledger Lock Detected:${NC}"
        echo "   $last_lock"
        echo ""
        echo "Another agent is performing a promotion. Please wait."
        return 1
    fi
    return 0
}

validate_agent_scope() {
    local agent="$1"
    local target_dir="${AGENT_DIRS[$agent]:-}"
    
    if [ -z "$target_dir" ]; then
        echo -e "${RED}❌ Unknown agent type: $agent${NC}"
        echo "Valid types: research, redesign, app"
        return 1
    fi
    
    # Get list of staged files
    local staged_files=$(git diff --cached --name-only 2>/dev/null)
    
    if [ -z "$staged_files" ]; then
        echo -e "${YELLOW}⚠️  No staged files to commit.${NC}"
        echo "Stage your changes with: git add <files>"
        return 1
    fi
    
    echo "Checking directory scope for agent: $agent"
    echo "Allowed directory: $target_dir"
    echo ""
    
    local violations=""
    
    for file in $staged_files; do
        local allowed=false
        
        if [ "$agent" = "app" ]; then
            # App agent: must be in src/ but NOT in excluded dirs
            if [[ "$file" == src/* ]]; then
                allowed=true
                for excluded in "${APP_EXCLUDED_DIRS[@]}"; do
                    if [[ "$file" == $excluded/* ]]; then
                        allowed=false
                        break
                    fi
                done
            fi
        else
            # Research/Redesign: must be in their specific directory
            if [[ "$file" == $target_dir/* ]]; then
                allowed=true
            fi
        fi
        
        if [ "$allowed" = false ]; then
            violations="$violations\n  - $file"
        fi
    done
    
    if [ -n "$violations" ]; then
        echo -e "${RED}❌ SCOPE VIOLATION: Files outside your designated directory:${NC}"
        echo -e "$violations"
        echo ""
        echo "Agent '$agent' can only commit files in: $target_dir"
        return 1
    fi
    
    echo -e "${GREEN}✅ All staged files are within scope${NC}"
    return 0
}

run_local_tests() {
    local agent="$1"
    local target_dir="${AGENT_DIRS[$agent]}"
    
    echo ""
    echo "Running local validation tests..."
    
    case "$agent" in
        research|redesign)
            # For ML agents, check if there are models to validate
            local staging_models=$(ls -d "$PROJECT_ROOT/models/staging"/*/ 2>/dev/null || true)
            if [ -n "$staging_models" ]; then
                for model_dir in $staging_models; do
                    echo "Validating: $model_dir"
                    if ! python3 "$VALIDATOR" "$model_dir" 2>/dev/null; then
                        echo -e "${RED}❌ Model validation failed${NC}"
                        return 1
                    fi
                done
            else
                echo "No models in staging to validate."
            fi
            ;;
        app)
            # For app agent, run TypeScript checks if available
            if [ -f "$PROJECT_ROOT/package.json" ]; then
                echo "Running type-check..."
                cd "$PROJECT_ROOT"
                if ! npm run type-check 2>/dev/null; then
                    echo -e "${RED}❌ TypeScript type-check failed${NC}"
                    return 1
                fi
            fi
            ;;
    esac
    
    echo -e "${GREEN}✅ Local tests passed${NC}"
    return 0
}

# =============================================================================
# Main Commit Logic
# =============================================================================

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  ANTIGRAVITY ATOMIC COMMIT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

# Validate arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}Usage: ./scripts/agent-commit.sh <agent-type> <message>${NC}"
    echo ""
    echo "Agent Types:"
    echo "  research  - Commits to src/ml/research/"
    echo "  redesign  - Commits to src/ml/redesign/"
    echo "  app       - Commits to src/ (excluding ML dirs)"
    exit 1
fi

AGENT_TYPE="$1"
COMMIT_MSG="$2"

cd "$PROJECT_ROOT" || exit 1

echo ""
echo "Agent:   $AGENT_TYPE"
echo "Message: $COMMIT_MSG"
echo ""

# Step 1: Check ledger lock
echo "Step 1: Checking ledger lock..."
if ! check_ledger_lock; then
    log_registry "BLOCKED" "$AGENT_TYPE" "LEDGER_LOCK"
    exit 1
fi
echo -e "${GREEN}✅ No lock detected${NC}"

# Step 2: Validate directory scope
echo ""
echo "Step 2: Validating directory scope..."
if ! validate_agent_scope "$AGENT_TYPE"; then
    log_registry "BLOCKED" "$AGENT_TYPE" "SCOPE_VIOLATION"
    exit 1
fi

# Step 3: Run local tests
echo ""
echo "Step 3: Running local validation..."
if ! run_local_tests "$AGENT_TYPE"; then
    log_registry "BLOCKED" "$AGENT_TYPE" "TEST_FAILURE"
    exit 1
fi

# Step 4: Perform atomic commit
echo ""
echo "Step 4: Committing changes..."

# Add agent metadata to commit message
FULL_MSG="[$AGENT_TYPE] $COMMIT_MSG"

if git commit -m "$FULL_MSG" 2>/dev/null; then
    COMMIT_HASH=$(git rev-parse --short HEAD)
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  COMMIT SUCCESSFUL${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo "  Agent:   $AGENT_TYPE"
    echo "  Commit:  $COMMIT_HASH"
    echo "  Message: $FULL_MSG"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    
    log_registry "SUCCESS" "$AGENT_TYPE" "$COMMIT_HASH"
    exit 0
else
    echo -e "${RED}❌ Commit failed${NC}"
    log_registry "FAILED" "$AGENT_TYPE" "GIT_ERROR"
    exit 1
fi
