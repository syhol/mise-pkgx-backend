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

This project uses mise tasks for common development workflows:

```bash
# Run tests
mise test              # Unit tests only
mise test:unit         # Unit tests only (explicit)
mise test:integration  # Unit and integration tests

# Plugin development workflow
mise plugin link pkgx .             # Link plugin for local development
mise --debug list-versions pkgx:git-scm.org  # Test with debug output
mise list-versions pkgx:git-scm.org # Test listing versions
mise use pkgx:git-scm.org@latest    # Test installation
mise exec pkgx:git-scm.org@latest -- which git  # Test execution environment
mise plugin rm pkgx                 # Remove when done

# Available mise tasks
mise tasks                          # List all available tasks
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
├── mise.toml                 # Mise configuration with test tasks
├── hooks/
│   ├── backend_exec_env.lua   # Environment setup
│   ├── backend_install.lua    # Installation logic
│   └── backend_list_versions.lua # Version fetching
├── mise-tasks/
│   └── test                  # Test runner script (mise task)
└── test/
    ├── test_platform_detection.lua # Unit tests for platform detection
    ├── test_version_listing.lua    # Unit tests for version listing
    ├── test_exec_env.lua           # Unit tests for environment setup
    └── test_integration.sh         # Full integration tests
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

**Unit Tests** (in `test/` directory):
- `test_platform_detection.lua`: Tests OS/architecture detection functions
- `test_version_listing.lua`: Tests version fetching and parsing logic  
- `test_exec_env.lua`: Tests PATH environment variable construction

**Integration Tests** (in `test/` directory):
- `test_integration.sh`: Full end-to-end testing (may be unstable due to alpha status)
- Tests plugin linking, backend invocation, and basic functionality
- Tests multiple tools: git-scm.org, nodejs.org, python.org

**Running Tests**:
```bash
# Run unit tests only (using mise task)
mise test
# or
mise test:unit

# Run unit and integration tests (requires mise)
mise test:integration

# Individual unit tests
lua test/test_platform_detection.lua
lua test/test_version_listing.lua  
lua test/test_exec_env.lua

# Direct script execution (alternative)
./mise-tasks/test
./mise-tasks/test --with-integration
```

## Development Best Practices

- Use `mise plugin link` for local development and testing
- Use `mise --debug` flag for troubleshooting hook execution
- Handle cross-platform scenarios (Linux/Darwin, x86-64/aarch64)
- Provide meaningful error messages with context
- Run test suite before making changes: `mise test:integration`
- Test all three hooks thoroughly before release