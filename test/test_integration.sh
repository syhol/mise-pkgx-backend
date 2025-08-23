#!/bin/bash
# Integration test script for mise-pkgx-backend plugin
# Tests the plugin with actual mise commands using multiple tools

set -e

export PLUGIN_NAME="pkgx-test"
CURRENT_DIR=$(pwd)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
    log "Cleaning up test environment..."

    # Uninstall test tools if installed
    # shellcheck disable=SC2066
    for tool in $(mise list --no-header | awk '{print $1}' | grep ^$PLUGIN_NAME); do
        log "Uninstalling $tool..."
        mise uninstall "$tool" || warn "Failed to uninstall $tool"
    done
    
    # Remove plugin
    if mise plugin list | grep -q "$PLUGIN_NAME"; then
        log "Removing plugin..."
        mise plugin rm "$PLUGIN_NAME" || warn "Failed to remove plugin"
    fi
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

main() {
    log "Starting integration tests for mise-pkgx-backend..."
    
    # Check if mise is available
    if ! command -v mise &> /dev/null; then
        error "mise is not installed or not in PATH"
        exit 1
    fi
    
    log "mise version: $(mise --version)"
    
    # Test 1: Link plugin
    log "Test 1: Linking plugin..."
    if mise plugin link "$PLUGIN_NAME" "$CURRENT_DIR" --force; then
        log "✓ Plugin linked successfully"
    else
        error "✗ Failed to link plugin"
        exit 1
    fi
    
    # Verify plugin is linked
    if mise plugin list | grep -q "$PLUGIN_NAME"; then
        log "✓ Plugin appears in plugin list"
    else
        error "✗ Plugin not found in plugin list"
        exit 1
    fi
    
    # Test 2: Test with multiple tools
    log "Test 2: Testing with multiple tools..."
    
    # Run e2e tests with error handling
    for e2e_file in test/e2e/*.e2e.sh; do
        if [[ -f "$e2e_file" ]]; then
            log "Running $(basename "$e2e_file")..."
            # shellcheck disable=SC1090
            if ! bash "$e2e_file"; then
                error "✗ E2E test failed: $(basename "$e2e_file")"
                exit 1
            fi
            log "✓ $(basename "$e2e_file") passed"
        fi
    done

    log "All integration tests passed! ✅"
}

# Run main function
main "$@"
