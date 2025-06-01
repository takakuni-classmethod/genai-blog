# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Finch is an open-source client for container development that provides a native, fast, and extensible container development experience. It integrates nerdctl (Docker-compatible CLI), containerd, BuildKit, and Lima (for VM management on macOS/Windows).

## Common Development Commands

### Building
```bash
# Standard build
make

# Platform-specific builds
make finch-macos    # macOS with universal binary
make finch-windows  # Windows executable
make finch-native   # Linux native build

# Install locally
make install        # Installs to /usr/local (macOS) or Program Files (Windows)

# Clean build artifacts
make clean
```

### Testing
```bash
# Run unit tests
make test-unit

# Run e2e tests (requires VM to be removed first)
make test-e2e

# Run specific test suites
make test-e2e-container
make test-e2e-vm

# Run a single test
go test -run TestName ./path/to/package

# Check coverage
make coverage
```

### Code Quality
```bash
# Run linter (must pass before committing)
make lint

# Generate mocks and other code
make gen-code

# Check licenses
make check-licenses
```

## Architecture Overview

### Platform Architecture
- **macOS/Windows**: Uses Lima to manage a Linux VM containing the container runtime
- **Linux**: Runs nerdctl/containerd natively without VM layer

### Key Components
1. **CLI Layer** (`cmd/finch/`): Cobra-based commands that wrap nerdctl functionality
2. **VM Management** (`pkg/lima/`): Lima integration for macOS/Windows platforms
3. **Configuration** (`pkg/config/`): Handles finch.yaml configuration with platform-specific validation
4. **Command Execution** (`pkg/command/`): Abstractions for executing nerdctl commands

### Code Organization
- Platform-specific code uses build tags and suffixes: `_darwin.go`, `_windows.go`, `_native.go`
- Remote vs native implementations: `_remote.go` (VM-based) vs `_native.go` (direct)
- All packages have corresponding mock interfaces in `pkg/mocks/`

### Important Patterns
- **Dependency Injection**: Constructors accept interfaces for testability
- **Command Pattern**: All nerdctl commands follow consistent interface patterns
- **Platform Abstraction**: Use build tags to separate platform-specific logic
- **VM State Management**: Always check VM status before executing container commands

## Development Guidelines

### Testing Requirements
- Every source file must have a corresponding test file
- Use `t.Parallel()` in unit tests unless there's a specific reason not to
- E2E tests must clean up resources (containers, volumes, networks)
- Mock external dependencies using generated mocks in `pkg/mocks/`

### Configuration Handling
- User config location: `~/.finch/finch.yaml` (macOS/Linux) or `%LOCALAPPDATA%\.finch\finch.yaml` (Windows)
- VM config changes require VM restart to take effect
- Always validate configuration changes using the appropriate platform validator

### VM Lifecycle (macOS/Windows)
- VM must be initialized before use: `finch vm init`
- Check VM status before container operations
- VM start/stop commands handle graceful shutdown
- VM removal (`finch vm remove`) required before running e2e tests

### Error Handling
- Wrap errors with context using `fmt.Errorf`
- Command execution errors should preserve exit codes
- VM errors should suggest appropriate recovery actions (init, start, etc.)