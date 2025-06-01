# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Finch is an open-source client for container development that provides a simplified experience for building, running, and managing containers. It integrates nerdctl, containerd, BuildKit, and Lima (on macOS/Windows) to provide a Docker-compatible container development environment.

## Key Architecture

### Platform Architecture
- **macOS/Windows**: Uses Lima to manage a Linux VM where container runtime components run. Finch CLI communicates with VM via SSH/socket forwarding.
- **Linux**: Runs containerd and nerdctl directly without virtualization.

### Core Components
- `cmd/finch/`: CLI entry point with platform-specific implementations
- `pkg/config/`: Configuration management (finch.yaml, VM settings, credential helpers)
- `pkg/lima/`: VM lifecycle management
- `pkg/dependency/`: VMNet setup, credential helper management
- `pkg/command/`: Command execution and nerdctl wrapping

## Development Commands

### Building
```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/runfinch/finch.git

# Build
make

# Binary location: _output/bin/finch
```

### Testing
```bash
# Unit tests
make test-unit

# E2E tests (ensure VM is stopped/removed first)
./_output/bin/finch vm stop && ./_output/bin/finch vm remove
make test-e2e

# Coverage check
make coverage
```

### Code Quality
```bash
# Lint code (runs for all platforms)
make lint

# Generate mocks and code
make gen-code

# Check licenses
make check-licenses
```

### Platform-Specific Testing
- VM tests: `e2e/vm/` - Finch-specific VM lifecycle tests
- Container tests: `e2e/container/` - Generic container workflow tests

## Code Style Guidelines

1. **Commit Messages**: Use Conventional Commits format with DCO sign-off
   - Format: `<type>(<scope>):<message>`
   - Platform-specific: `feat(Windows):`, `fix(macOS):`
   - Sign commits: `git commit -s`

2. **Go Files**: 
   - Use underscores, not hyphens or camelCase
   - Prefer single-word names when possible
   - Each `.go` file should have corresponding `_test.go`

3. **Testing**:
   - Unit tests must use `t.Parallel()` by default
   - Mock generation via `mockgen` (interfaces in `pkg/mocks/`)
   - E2E tests use Ginkgo framework

## Configuration Files

- `finch.yaml`: User configuration (VM resources, snapshotters, credential helpers)
- `config.yaml`: Default VM configuration template
- `networks.yaml`: Lima VM networking configuration
- `finch.yaml.d/`: Additional configuration snippets

## Important Development Notes

1. **Submodules**: The project uses git submodules for `deps/finch-core`. Always clone with `--recurse-submodules`.

2. **Platform Variations**: 
   - File suffixes indicate platform-specific code: `_darwin.go`, `_windows.go`, `_linux.go`
   - Remote vs native: `_remote.go` (VM-based) vs `_native.go` (direct containerd)

3. **Before Submitting PRs**:
   - Run all tests: `make test-unit && make test-e2e`
   - Run linter: `make lint`
   - Ensure `make gen-code` produces no diffs
   - Update docs if adding commands: `./_output/bin/finch gen-docs generate -p ./docs/cmd`

4. **VM Management**: 
   - macOS uses Virtualization.framework (default) or QEMU
   - Windows uses WSL2
   - VM lifecycle managed through Lima

5. **Docker Compatibility**: 
   - Finch daemon provides Docker-compatible socket
   - Supports DevContainers through finch-daemon
   - Most Docker commands work via nerdctl wrapper