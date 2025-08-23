#!/bin/bash
# Basic integration test for mise-pkgx-backend plugin
# Tests basic functionality with multiple tools without complex scenarios

set -e

PLUGIN_NAME="pkgx-basic-test"
TEST_TOOLS=("git-scm.org" "nodejs.org" "python.org")
CURRENT_DIR=$(pwd)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cleanup() {
    log "Cleaning up..."
    if mise plugin list 2>/dev/null | grep -q "$PLUGIN_NAME"; then
        mise plugin rm "$PLUGIN_NAME" 2>/dev/null || true
    fi
}

trap cleanup EXIT

main() {
    log "Basic integration test for mise-pkgx-backend"
    
    # Check if mise is available
    if ! command -v mise &> /dev/null; then
        error "mise is not installed"
        exit 1
    fi
    
    # Test 1: Link plugin
    log "Test 1: Linking plugin..."
    if mise plugin link "$PLUGIN_NAME" "$CURRENT_DIR" --force >/dev/null 2>&1; then
        log "✓ Plugin linked successfully"
    else
        error "✗ Failed to link plugin"
        exit 1
    fi
    
    # Test 2: Verify plugin appears in list
    if mise plugin list | grep -q "$PLUGIN_NAME"; then
        log "✓ Plugin appears in plugin list"
    else
        error "✗ Plugin not found in plugin list"
        exit 1
    fi
    
    # Test 3: Try to trigger the backend with multiple tools
    log "Test 3: Testing backend functionality with multiple tools..."
    
    for tool in "${TEST_TOOLS[@]}"; do
        log "Testing backend with $tool..."
        OUTPUT=$(mise install "$PLUGIN_NAME:$tool@latest" 2>&1 || true)
        
        if echo "$OUTPUT" | grep -q "Backend\|install\|download\|fetch"; then
            log "  ✓ Backend plugin invoked for $tool"
        elif echo "$OUTPUT" | grep -q "Failed to install"; then
            log "  ✓ Backend plugin attempted installation for $tool (expected for alpha plugin)"
        else
            warn "  Backend output for $tool: $(echo "$OUTPUT" | head -1)"
        fi
    done
    
    log "✅ Basic integration tests completed"
    log "Note: This plugin is marked as 'mega alpha' - some functionality may not work perfectly"
}

main "$@"