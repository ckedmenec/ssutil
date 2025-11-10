# ssutil - Simplicity Studio Utility

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg)]()
[![Simplicity Studio: 5 & 6](https://img.shields.io/badge/Simplicity_Studio-5_%26_6-blue.svg)]()
[![Shell Script](https://img.shields.io/badge/shell-bash-89e051.svg)]()

> A unified command-line build and flash tool for Silicon Labs Simplicity Studio projects

**ssutil** streamlines your Silicon Labs embedded development workflow with a single script that auto-detects your project structure, build system, and provides a clean CLI interface with colored output.

## ✨ Features

- 🔍 **Auto-detection** - Automatically finds your project and bootloader directories
- 🎨 **Colored output** - Compiler errors in red, warnings in yellow, build status in color
- 🔄 **Dual compatibility** - Works seamlessly with Studio 5 (Make) and Studio 6 (CMake/Ninja)
- ⚡ **Fast builds** - Parallel compilation with optimal job count detection
- 🎯 **Flexible modes** - Build-only, flash-only, or build-and-flash
- 📝 **Build logging** - Automatic build.log with full output capture
- 🧹 **Clean builds** - One flag to clean and rebuild everything
- 🚫 **No dependencies** - Pure bash, works with tools bundled in Simplicity Studio

## 🚀 Quick Start

```bash
# Clone the repo
git clone https://github.com/ckedmenec/ssutil.git
cd ssutil

# Copy to your Simplicity Studio solution directory
cp ssutil.sh /path/to/YourSimplicitySolution/

# Make it executable (if needed)
chmod +x ssutil.sh

# Run it!
./ssutil.sh
```

## 📦 Installation

### Option 1: Manual Copy
```bash
# Download the script
curl -O https://raw.githubusercontent.com/ckedmenec/ssutil/main/ssutil.sh
chmod +x ssutil.sh

# Place it in your Simplicity Studio solution directory
mv ssutil.sh /path/to/YourProject/
```

### Option 2: Global Installation
```bash
# Install globally (requires sudo)
curl -sSL https://raw.githubusercontent.com/ckedmenec/ssutil/main/install.sh | bash

# Now you can run from any Simplicity Studio solution directory
cd /path/to/YourProject
ssutil
```

## 💡 Usage

### Basic Commands

```bash
./ssutil.sh              # Auto-detect, build and flash (default)
./ssutil.sh --help       # Show all options and examples
```

### Build Modes

```bash
./ssutil.sh -B           # Build only (no flash)
./ssutil.sh -F           # Flash only (use existing binaries)
./ssutil.sh -c           # Clean build and flash
./ssutil.sh -B -c        # Clean build only (no flash)
```

### Advanced Usage

```bash
# Mass erase device and flash bootloader + application
./ssutil.sh -e

# Build bootloader + application (no flash/erase)
./ssutil.sh -B -e

# Specify project manually (skip auto-detection)
./ssutil.sh --project MyProject --bootloader MyBootloader

# Disable colored output (for CI/CD or logging)
./ssutil.sh --no-color
```

### All Options

```
Options:
  -e, --erase              Mass erase device and flash bootloader first
  -c, --clean              Clean build before compiling
  -B, --build-only         Build only (skip flashing and device operations)
  -F, --flash-only         Flash only (skip building, use existing binaries)
  -p, --project <name>     Specify project directory name (auto-detected if not provided)
  -b, --bootloader <name>  Specify bootloader directory name (auto-detected if not provided)
  --no-color               Disable colored output
  -h, --help               Show help message
```

## 🎯 Project Support

### Simplicity Studio 5
- ✅ GNU ARM v12.2.1 toolchain
- ✅ Make-based builds
- ✅ Matter, Thread, Zigbee, Bluetooth projects
- ✅ Build directory: `GNU ARM v12.2.1 - Default/`

### Simplicity Studio 6
- ✅ CMake + Ninja builds
- ✅ Auto-detects `cmake_gcc/build` structure
- ✅ Full Matter SDK support
- ✅ Automatic Ninja discovery in Silabs tools directory

## 🔧 How It Works

1. **Auto-Detection**: Scans for build directories (`GNU ARM*` or `cmake_gcc`)
2. **Build System Selection**: Automatically chooses Make or CMake/Ninja
3. **Colored Output**: Uses `script` command to preserve compiler colors
4. **Parallel Builds**: Detects CPU count and runs parallel jobs
5. **Smart Flashing**: Finds `.s37` binaries and uses Simplicity Commander

## 🛠️ Requirements

- **OS**: macOS (tested on macOS 14.0+, should work on 11.0+)
- **Tools**: Simplicity Studio 5 or 6 installed
- **Commander**: Simplicity Commander (bundled with Studio)
- **Shell**: Bash 4.0+

## 📂 Project Structure

Your Simplicity Studio solution should look like this:

### Studio 5 Structure:
```
YourSolution/
├── ssutil.sh
├── YourProject/
│   └── GNU ARM v12.2.1 - Default/
│       ├── makefile
│       └── *.o, *.s37
└── Matter-Bootloader/          # Optional
    └── GNU ARM v12.2.1 - Default/
```

### Studio 6 Structure:
```
YourSolution/
├── ssutil.sh
├── YourProject/
│   └── cmake_gcc/
│       └── build/
│           └── base/*.s37
└── Matter-Bootloader/          # Optional
    └── cmake_gcc/build/
```

## 🎬 Example Workflow

```bash
# Day-to-day development
./ssutil.sh              # Quick build and flash

# After changing configuration or adding files
./ssutil.sh -c           # Clean build and flash

# CI/CD pipeline
./ssutil.sh -B --no-color > build.log 2>&1

# Recovering from corruption
./ssutil.sh -e           # Mass erase, rebuild bootloader, flash everything
```

## 🐛 Troubleshooting

### "No project directory found"
- Make sure you're running the script from your Simplicity Studio solution directory
- Check that your project has a `GNU ARM*` or `cmake_gcc/build` directory

### "Ninja: No such file or directory"
- The script will automatically find Ninja in `/Users/<you>/.silabs/slt/installs/`
- If not found, it falls back to `cmake --build`

### Colors don't appear
- Colors are automatically disabled when output is piped
- Run directly in terminal: `./ssutil.sh` (not `./ssutil.sh | tee`)
- Use `--no-color` flag to explicitly disable

### Build fails but GUI works
- Check `build.log` in your build directory for detailed errors
- Try running with `-c` for a clean build
- Verify Simplicity Studio can build the project

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Reporting Bugs
- Open an issue with the `bug` label
- Include your OS version, Simplicity Studio version, and project type
- Attach relevant portions of `build.log`

### Suggesting Features
- Open an issue with the `enhancement` label
- Describe your use case and proposed solution

### Pull Requests
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Test with both SS5 and SS6 projects
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for the Silicon Labs embedded developer community
- Inspired by the need for faster CI/CD workflows
- Thanks to the Matter, Thread, and Zigbee communities for testing

## 📊 Roadmap

- [x] Simplicity Studio 5 support
- [x] Simplicity Studio 6 support
- [x] Auto-detection of projects
- [x] Colored build output
- [ ] Linux support
- [ ] Windows support (WSL/Git Bash)
- [ ] Global installation script
- [ ] Configuration file support (`.ssutil.conf`)
- [ ] Multiple project builds in one command

## ❓ FAQ

**Q: Does this replace Simplicity Studio?**
A: No, it's a complement. Use it for faster command-line builds, CI/CD, or when you prefer terminal workflows.

**Q: Will this work with my Matter/Thread/Zigbee project?**
A: Yes! It works with any Simplicity Studio project that uses Make or CMake.

**Q: Can I use this in CI/CD?**
A: Absolutely! Use `./ssutil.sh -B --no-color` for headless builds.

**Q: Does it work on Linux/Windows?**
A: Currently macOS only. Linux support is planned. Windows may work via WSL (untested).

## 📬 Support

- **Issues**: [GitHub Issues](https://github.com/ckedmenec/ssutil/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ckedmenec/ssutil/discussions)

---

**⭐ If this tool saves you time, please consider giving it a star!**

Made with ❤️ for the Silicon Labs developer community
