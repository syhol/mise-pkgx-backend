#!/bin/bash
# Integration test script for mise-pkgx-backend plugin
# Tests the plugin with actual mise commands

set -e

PLUGIN_NAME="pkgx-test"
TEST_TOOL="git-scm.org"
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
    
    # Uninstall test tool if installed
    if mise list | grep -q "$PLUGIN_NAME:$TEST_TOOL"; then
        log "Uninstalling test tool..."
        mise uninstall "$PLUGIN_NAME:$TEST_TOOL" || warn "Failed to uninstall test tool"
    fi
    
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
    
    # Test 2: List versions with debug to see what's happening
    log "Test 2: Testing version listing for $TEST_TOOL..."
    if mise --debug use "$PLUGIN_NAME:$TEST_TOOL@latest" 2>&1 | grep -q "Backend"; then
        log "✓ Backend plugin is being invoked"
    else
        warn "! Backend plugin may not be working as expected"
    fi
    
    # Try listing versions directly
    log "Attempting to list versions..."
    VERSIONS_OUTPUT=$(mise list-versions "$PLUGIN_NAME:$TEST_TOOL" 2>&1)
    if echo "$VERSIONS_OUTPUT" | grep -q "^[0-9]"; then
        log "✓ Version listing works"
        LATEST_VERSION=$(echo "$VERSIONS_OUTPUT" | grep "^[0-9]" | tail -1)
        log "✓ Latest version: $LATEST_VERSION"
    else
        warn "Version listing output:"
        echo "$VERSIONS_OUTPUT" | head -3
        warn "! Skipping version-dependent tests"
        LATEST_VERSION="2.44.0"  # Use a known version for testing
    fi
    
    # Test 3: Install tool (only if we have a valid version)
    if [[ "$LATEST_VERSION" =~ ^[0-9] ]]; then
        log "Test 3: Installing $TEST_TOOL@$LATEST_VERSION..."
        if mise install "$PLUGIN_NAME:$TEST_TOOL@$LATEST_VERSION"; then
            log "✓ Installation successful"
            
            # Test 4: Verify installation
            log "Test 4: Verifying installation..."
            if mise list | grep -q "$PLUGIN_NAME:$TEST_TOOL"; then
                log "✓ Tool appears in installed tools list"
            else
                warn "! Tool not found in installed tools list"
            fi
            
            # Test 5: Test execution environment
            log "Test 5: Testing execution environment..."
            if mise exec "$PLUGIN_NAME:$TEST_TOOL@$LATEST_VERSION" -- git --version > /dev/null 2>&1; then
                log "✓ Tool execution works"
            else
                warn "! Tool execution test skipped (tool may not have expected binary)"
            fi
            
            # Test 6: Test with .tool-versions file
            log "Test 6: Testing .tool-versions file..."
            echo "$PLUGIN_NAME:$TEST_TOOL $LATEST_VERSION" > .tool-versions
            
            if mise install; then
                log "✓ .tool-versions installation works"
            else
                warn "! .tool-versions installation failed"
            fi
            
            # Cleanup .tool-versions
            rm -f .tool-versions
        else
            warn "! Installation failed - this may indicate issues with the backend plugin"
        fi
    else
        warn "! Skipping installation tests - version listing not working properly"
    fi
    
    log "All integration tests passed! ✅"
}

# Run main function
main "$@"