#!/bin/bash
# =============================================================================
# failsafe-monitor.sh - The Global Git-Backplane Failsafe
# =============================================================================
# This script monitors the health of all ML containers and automatically
# reverts failed components to the last known good state.
#
# Usage:
#   ./scripts/failsafe-monitor.sh
#
# The script runs continuously, checking container health every 30 seconds.
# To stop: Ctrl+C or send SIGTERM
# =============================================================================

set -uo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$PROJECT_ROOT/logs"
REGISTRY_LOG="$PROJECT_ROOT/registry.log"
POLL_INTERVAL=30

# Service-to-directory mapping
declare -A SERVICE_DIRS=(
    ["ml-research"]="src/ml/research"
    ["ml-redesign"]="src/ml/redesign"
    ["app"]="src"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure logs directory exists
mkdir -p "$LOGS_DIR"

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo -e "[$timestamp] [$level] $message"
    echo "[$timestamp] [$level] $message" >> "$LOGS_DIR/failsafe.log"
}

log_registry() {
    local action="$1"
    local service="$2"
    local status="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] [FAILSAFE] [$action] [$service] [$status]" >> "$REGISTRY_LOG"
}

# =============================================================================
# Health Check Functions
# =============================================================================

check_unhealthy_containers() {
    # Returns list of unhealthy service names
    docker compose ps --format "{{.Service}}\t{{.Health}}" 2>/dev/null | \
        grep -E "unhealthy|starting" | \
        awk '{print $1}'
}

check_exited_containers() {
    # Returns list of exited/crashed containers
    docker compose ps --format "{{.Service}}\t{{.State}}" 2>/dev/null | \
        grep -E "exited|dead" | \
        awk '{print $1}'
}

# =============================================================================
# Rollback Functions
# =============================================================================

revert_service() {
    local service="$1"
    local target_dir="${SERVICE_DIRS[$service]:-}"
    
    if [ -z "$target_dir" ]; then
        log "ERROR" "Unknown service: $service. Cannot determine directory to revert."
        return 1
    fi
    
    log "WARN" "Reverting $service ($target_dir) to last Git HEAD..."
    
    cd "$PROJECT_ROOT" || return 1
    
    # Check if there are uncommitted changes
    if git diff --quiet "$target_dir" 2>/dev/null; then
        log "INFO" "No changes detected in $target_dir. Skipping revert."
        return 0
    fi
    
    # Revert to HEAD
    if git checkout HEAD -- "$target_dir" 2>/dev/null; then
        log "SUCCESS" "Reverted $target_dir to HEAD successfully."
        log_registry "ROLLBACK" "$service" "SUCCESS"
        return 0
    else
        log "ERROR" "Failed to revert $target_dir. Manual intervention required."
        log_registry "ROLLBACK" "$service" "FAILED"
        return 1
    fi
}

restart_service() {
    local service="$1"
    
    log "INFO" "Restarting container: $service..."
    
    if docker compose restart "$service" 2>/dev/null; then
        log "SUCCESS" "Container $service restarted."
        log_registry "RESTART" "$service" "SUCCESS"
        return 0
    else
        log "ERROR" "Failed to restart $service."
        log_registry "RESTART" "$service" "FAILED"
        return 1
    fi
}

# =============================================================================
# Failsafe Handler
# =============================================================================

handle_failure() {
    local service="$1"
    local reason="$2"
    
    echo ""
    log "ALERT" "═══════════════════════════════════════════════════════════"
    log "ALERT" "FAILSAFE TRIGGERED: $service is $reason"
    log "ALERT" "═══════════════════════════════════════════════════════════"
    
    # Step 1: Log the failure
    log_registry "FAILURE_DETECTED" "$service" "$reason"
    
    # Step 2: Revert the directory
    if revert_service "$service"; then
        # Step 3: Restart the container
        restart_service "$service"
    else
        log "ERROR" "Rollback failed. Service $service requires manual intervention."
        echo "CRITICAL: Manual intervention required for $service" >> "$LOGS_DIR/failsafe.log"
    fi
    
    echo ""
}

# =============================================================================
# Global Success Snapshot
# =============================================================================

create_success_snapshot() {
    local tag_name="stable-checkpoint-$(date +%Y-%m-%d-%H%M%S)"
    
    log "INFO" "All containers healthy. Creating success snapshot..."
    
    cd "$PROJECT_ROOT" || return 1
    
    # Check if there are changes to commit
    if git diff --quiet && git diff --cached --quiet; then
        log "INFO" "No changes to snapshot. Skipping."
        return 0
    fi
    
    # Create a lightweight tag at current HEAD
    if git tag "$tag_name" 2>/dev/null; then
        log "SUCCESS" "Created snapshot tag: $tag_name"
        log_registry "SNAPSHOT" "ALL" "$tag_name"
        return 0
    else
        log "WARN" "Failed to create tag (may already exist or not a git repo)"
        return 1
    fi
}

# =============================================================================
# Main Monitor Loop
# =============================================================================

print_banner() {
    echo -e "${BLUE}"
    echo "═══════════════════════════════════════════════════════════════════"
    echo "  ANTIGRAVITY FAILSAFE MONITOR"
    echo "  Git-Backplane Architecture v1.0"
    echo "═══════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    echo "Monitoring containers every ${POLL_INTERVAL}s..."
    echo "Press Ctrl+C to stop."
    echo ""
}

cleanup() {
    echo ""
    log "INFO" "Failsafe monitor shutting down..."
    exit 0
}

trap cleanup SIGINT SIGTERM

main() {
    print_banner
    
    local consecutive_healthy=0
    local SNAPSHOT_THRESHOLD=10  # Create snapshot after 10 consecutive healthy checks
    
    while true; do
        # Check for unhealthy containers
        local unhealthy=$(check_unhealthy_containers)
        local exited=$(check_exited_containers)
        
        if [ -n "$unhealthy" ]; then
            consecutive_healthy=0
            for service in $unhealthy; do
                handle_failure "$service" "unhealthy"
            done
        elif [ -n "$exited" ]; then
            consecutive_healthy=0
            for service in $exited; do
                handle_failure "$service" "exited"
            done
        else
            ((consecutive_healthy++))
            log "OK" "All containers healthy. (${consecutive_healthy}/${SNAPSHOT_THRESHOLD})"
            
            # Create snapshot after sustained health
            if [ $consecutive_healthy -ge $SNAPSHOT_THRESHOLD ]; then
                create_success_snapshot
                consecutive_healthy=0
            fi
        fi
        
        sleep $POLL_INTERVAL
    done
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
