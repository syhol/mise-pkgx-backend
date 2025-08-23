# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a mise backend plugin written in Lua that enables installing CLI tools from the pkgxdev/pantry registry. The plugin provides native Lua integration with mise, allowing users to install and manage tools using the `pkgx:` prefix.

## Architecture

The plugin follows mise's backend plugin architecture with three main hook files:

- **hooks/backend_list_versions.lua**: Fetches available versions for a tool from dist.pkgx.dev
- **hooks/backend_install.lua**: Downloads, extracts, and installs tools with dependency resolution
- **hooks/backend_exec_env.lua**: Sets up PATH environment variables for installed tools
- **metadata.lua**: Plugin metadata and configuration

### Key Components

**Platform Detection**: Both `backend_install.lua` and `backend_list_versions.lua` include platform detection functions that:
- Detect OS (Linux/Darwin) via `uname -s`
- Detect architecture (x86-64/aarch64) via `uname -m`
- Map to pkgx distribution naming conventions

**Dependency Resolution**: The install hook fetches package.yml files from pkgxdev/pantry to resolve dependencies and recursively installs them.

**Version Management**: Creates symlinks for major, major.minor, and wildcard versions to enable flexible version matching.

## Development Commands

Since this is a Lua-based mise plugin, there are no traditional build/test commands. Development workflow:

```bash
# Link plugin for local development
mise plugin link pkgx .

# Test with debug output
mise --debug list-versions pkgx:git-scm.org

# Test listing versions
mise list-versions pkgx:git-scm.org

# Test installation
mise use pkgx:git-scm.org@latest

# Test execution environment
mise exec pkgx:git-scm.org@latest -- which git

# Unlink when done
mise plugin unlink pkgx
```

## API Integration

The plugin integrates with two main external APIs:
- **dist.pkgx.dev**: Binary distribution service for downloading pre-built tools
- **raw.githubusercontent.com/pkgxdev/pantry**: Package metadata repository for dependency information

URL patterns:
- Versions: `https://dist.pkgx.dev/{tool}/{platform}/{arch}/versions.txt`
- Downloads: `https://dist.pkgx.dev/{tool}/{platform}/{arch}/v{version}.tar.gz`
- Dependencies: `https://raw.githubusercontent.com/pkgxdev/pantry/main/projects/{tool}/package.yml`

## File Structure

```
├── metadata.lua              # Plugin metadata
└── hooks/
    ├── backend_exec_env.lua   # Environment setup
    ├── backend_install.lua    # Installation logic
    └── backend_list_versions.lua # Version fetching
```

## Hook Function Implementation

The plugin implements the three core mise backend hooks:

**BackendListVersions**: Returns `{versions = array}` with available versions from dist.pkgx.dev
**BackendInstall**: Downloads and extracts tools, handles dependencies, returns `{success = true}`
**BackendExecEnv**: Returns `{env_vars = array}` with PATH modifications for tool binaries

Each hook receives a `ctx` parameter with `tool`, `version`, and `install_path` fields.

## Error Handling

The plugin includes error handling for:
- Unsupported platforms/architectures
- Network failures during version fetching or downloads
- Archive extraction failures
- Missing dependency information (treated as optional)

## Testing

The project includes comprehensive test suites:

**Unit Tests**:
- `test_platform_detection.lua`: Tests OS/architecture detection functions
- `test_version_listing.lua`: Tests version fetching and parsing logic  
- `test_exec_env.lua`: Tests PATH environment variable construction

**Integration Tests**:
- `test_basic_integration.sh`: Basic integration testing with actual mise commands
- `test_integration.sh`: Full end-to-end testing (may be unstable due to alpha status)
- Tests plugin linking, backend invocation, and basic functionality

**Running Tests**:
```bash
# Run unit tests only
./run_tests.sh

# Run unit and integration tests (requires mise)
./run_tests.sh --with-integration

# Individual unit tests
lua test_platform_detection.lua
lua test_version_listing.lua  
lua test_exec_env.lua

# Basic integration test only
./test_basic_integration.sh
```

## Development Best Practices

- Use `mise plugin link` for local development and testing
- Use `mise --debug` flag for troubleshooting hook execution
- Handle cross-platform scenarios (Linux/Darwin, x86-64/aarch64)
- Provide meaningful error messages with context
- Run test suite before making changes: `./run_tests.sh --with-integration`
- Test all three hooks thoroughly before release