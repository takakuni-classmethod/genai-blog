# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Finch is an open source client for container development that provides a simple native client integrated with nerdctl, containerd, and BuildKit. On macOS and Windows, these components run within a Lima VM.

## Common Development Commands

### Build Commands
- `make` - Build all components for the current platform
- `make finch` - Build just the finch binary
- `make release` - Build release artifacts with licenses
- `make gen-code` - Generate mocks and other code using go generate
- `make clean` - Clean build artifacts and kill running processes

### Test Commands
- `make test-unit` - Run unit tests with 60% coverage threshold
- `make test-e2e` - Run all e2e tests (VM and container) - requires VM to be removed first
- `make test-e2e-vm-serial` - Run VM e2e tests only
- `make test-e2e-container` - Run container e2e tests only
- `make test-benchmark` - Run all benchmarks
- `make coverage` - Generate coverage report and open in browser

### Lint Commands
- `make lint` - Run golangci-lint for all platforms (darwin, windows)
- `make mdlint` - Run markdown lint on all .md files
- `make check-licenses` - Verify dependency licenses are allowed

### Single Test Execution
To run a single test:
```bash
go test -v ./path/to/package -run TestName
# For ginkgo tests:
go test -v ./e2e/vm -ginkgo.focus="test description"
```

## High-Level Architecture

### Platform-Specific Implementation
- **macOS/Windows**: Uses Lima VM to run containerd/nerdctl stack
  - VM management via `finch vm` commands
  - Configuration in `~/.finch/finch.yaml` (macOS) or `%LOCALAPPDATA%\.finch\finch.yaml` (Windows)
- **Linux**: Native execution without VM layer
  - Direct containerd/nerdctl integration

### Core Components
1. **Command Layer** (`cmd/finch/`)
   - Platform-specific entry points (main_darwin.go, main_windows.go, main_native.go)
   - VM management commands (virtual_machine_*.go)
   - Nerdctl command wrapper (nerdctl_*.go)

2. **Configuration System** (`pkg/config/`)
   - Platform-specific defaults and validation
   - Lima configuration management for VM platforms
   - Nerdctl configuration management

3. **VM Management** (`pkg/lima/`)
   - Lima wrapper for VM lifecycle
   - Network and disk management

4. **Dependency Management** (`deps/finch-core/`)
   - External component management (lima, nerdctl, containerd, buildkit)
   - Version synchronization across components

### Key Architectural Patterns
- **Platform Abstraction**: Heavy use of build tags and platform-specific files
- **Mock Generation**: Extensive use of mockgen for unit testing
- **E2E Test Isolation**: VM and container tests must run sequentially
- **Docker Compatibility**: Optional mode to accept Docker-like commands

### Important Interfaces
- `LimaWrapper` - VM management abstraction
- `NerdctlCmdCreator` - Command creation abstraction
- `Dependency` - External component management

## Platform-Specific Considerations

### macOS
- Supports both Intel and Apple Silicon (M1+)
- Choice of QEMU or Virtualization.framework hypervisors
- Optional Rosetta support for x86_64 emulation on Apple Silicon

### Windows
- Requires WSL 2
- No resource limit configuration due to WSL limitations
- Uses Windows-specific path handling

### Linux
- Native execution without VM overhead
- Requires containerd 1.7.x+ compatible kernel