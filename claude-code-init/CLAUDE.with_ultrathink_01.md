# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Finch is an open-source container development tool that provides a simple client integrated with nerdctl, containerd, BuildKit, and Lima. It supports macOS, Windows, and Linux, with platform-specific implementations for VM management.

## Architecture

### Platform Architecture
- **macOS/Windows (Remote)**: Uses Lima VM to run containerd/nerdctl inside a Linux VM
- **Linux (Native)**: Runs nerdctl directly without VM layer

### Key Components
- **Command Layer**: `cmd/finch/` - Entry points and command definitions
  - Platform-specific implementations: `main_darwin.go`, `main_windows.go`, `main_native.go` 
  - Nerdctl command wrapper: `nerdctl.go`, `nerdctl_remote.go`, `nerdctl_native.go`
- **Core Packages**: `pkg/`
  - `command/`: Command execution abstraction
  - `config/`: Configuration management
  - `lima/`: Lima VM integration (macOS/Windows)
  - `dependency/`: External dependency management
  - `disk/`: Disk management for VMs

### Command Flow
1. User runs `finch <command>`
2. Platform-specific main function initializes dependencies
3. Commands are routed to either:
   - Direct nerdctl execution (Linux)
   - Lima VM + nerdctl execution (macOS/Windows)
4. VM lifecycle commands (`finch vm *`) are handled separately

## Common Development Tasks

### Build
```bash
# Build for current platform
make

# Platform-specific builds
GOOS=darwin make
GOOS=windows make
GOOS=linux make

# Build and install
make install
```

### Testing
```bash
# Run unit tests
make test-unit

# Run e2e tests (VM must not exist)
# Remove VM first if it exists:
./_output/bin/finch vm stop
./_output/bin/finch vm remove
# Then run tests:
make test-e2e

# Run specific test suites
make test-e2e-container
make test-e2e-vm

# Check test coverage
make coverage
```

### Linting and Code Quality
```bash
# Run golangci-lint
make lint

# Lint markdown files
make mdlint

# Check licenses
make check-licenses

# Generate mocks and code
make gen-code
```

### VM Management (macOS/Windows)
```bash
# Initialize VM
./_output/bin/finch vm init

# Start/stop VM
./_output/bin/finch vm start
./_output/bin/finch vm stop

# Remove VM
./_output/bin/finch vm remove

# Shell into VM
# macOS:
LIMA_HOME=/Applications/Finch/lima/data /Applications/Finch/lima/bin/limactl shell finch
# Windows:
wsl -d lima-finch
```

## Key Files and Directories

- **Configuration**: 
  - User config: `~/.finch/finch.yaml` (macOS), `%LOCALAPPDATA%\.finch\finch.yaml` (Windows)
  - Default configs: `finch.yaml.d/`
- **Nerdctl Commands**: Defined in `cmd/finch/nerdctl.go:122` (nerdctlCmds map)
- **Platform Build Tags**:
  - `//go:build darwin || windows` for remote platforms
  - `//go:build linux` for native
- **Submodules**: `deps/finch-core` - Contains Lima and other core dependencies

## Platform-Specific Considerations

### macOS
- Uses Virtualization.framework (default) or QEMU
- Requires macOS 10.15+
- VM configuration in `finch.yaml` (CPUs, memory, etc.)

### Windows
- Uses WSL2
- Requires Windows 10 2004+
- Limited resource configuration due to WSL2 limitations

### Linux
- Native execution without VM
- Requires containerd 1.7.x+
- May need sudo/root for certain operations

## Testing Guidelines

- Unit tests should use `t.Parallel()` by default
- E2E tests are divided into:
  - Container tests: Generic container workflows (in `e2e/container/`)
  - VM tests: Finch-specific VM lifecycle (in `e2e/vm/`)
- Use Focus decorator during development but remove before PR
- Check CI status after merge due to "Loose" branch protection

## Code Conventions

- File naming: Use underscores for multi-word files (e.g., `lima_config_applier.go`)
- Imports: Group and order imports (stdlib, external, internal)
- Error handling: Wrap errors with context
- Platform code: Use build tags for platform-specific code
- Mocking: Use mockgen for generating mocks (see `pkg/tools.go`)

## Debugging

- Use `--debug` flag to enable debug logging
- VM logs available via Lima commands
- Check VM status with `finch vm status`