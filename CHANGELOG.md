# Changelog

All notable changes to ssutil will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-10

### Added
- Initial public release
- Auto-detection of Simplicity Studio projects and bootloaders
- Support for Simplicity Studio 5 (GNU ARM Make-based builds)
- Support for Simplicity Studio 6 (CMake/Ninja builds)
- Colored compiler output with error/warning highlighting
- Build log capture while preserving colors
- Build-only mode (`-B` flag)
- Flash-only mode (`-F` flag)
- Clean build support (`-c` flag)
- Mass erase and bootloader flashing (`-e` flag)
- Parallel builds with automatic CPU detection
- Manual project/bootloader specification
- Color disable option for CI/CD (`--no-color`)
- Automatic Ninja discovery in Silabs tools directory
- Fallback to `cmake --build` when Ninja not found
- Comprehensive help documentation
- MIT License
- Installation script for global usage

### Technical Details
- Pure bash implementation (no external dependencies beyond Studio tools)
- Compatible with macOS 11.0+
- Supports both Matter, Thread, Zigbee, and Bluetooth projects
- Intelligent build system detection (Make vs CMake)
- Smart binary artifact discovery (.s37/.hex files)

## [Unreleased]

### Planned
- Linux support
- Windows support (WSL/Git Bash)
- Configuration file support (.ssutil.conf)
- Multiple project builds in one command
- Build time reporting
- Automatic git tagging on successful builds
