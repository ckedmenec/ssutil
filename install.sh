#!/bin/bash
################################################################################
# ssutil - Installation Script
# Installs ssutil globally to /usr/local/bin
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    printf "${GREEN}✅ %s${NC}\n" "$1"
}

print_error() {
    printf "${RED}❌ %s${NC}\n" "$1"
}

print_info() {
    printf "${BLUE}ℹ️  %s${NC}\n" "$1"
}

print_warning() {
    printf "${YELLOW}⚠️  %s${NC}\n" "$1"
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ssutil - Simplicity Studio Utility Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_warning "This installer is designed for macOS"
    print_info "For other platforms, manually copy ssutil.sh to your project directory"
    exit 1
fi

# Detect installation method
if [[ -f "ssutil.sh" ]]; then
    # Local installation (git clone)
    SCRIPT_SOURCE="$(pwd)/ssutil.sh"
    print_info "Installing from local repository..."
elif [[ -n "$1" ]]; then
    # Manual path provided
    SCRIPT_SOURCE="$1"
    print_info "Installing from: $SCRIPT_SOURCE"
else
    # Download from GitHub
    print_info "Downloading latest version from GitHub..."
    TEMP_DIR=$(mktemp -d)
    curl -sSL https://raw.githubusercontent.com/ckedmenec/ssutil/main/ssutil.sh -o "$TEMP_DIR/ssutil.sh"
    SCRIPT_SOURCE="$TEMP_DIR/ssutil.sh"
fi

# Check if source file exists
if [[ ! -f "$SCRIPT_SOURCE" ]]; then
    print_error "Source file not found: $SCRIPT_SOURCE"
    exit 1
fi

# Installation directory
INSTALL_DIR="/usr/local/bin"
INSTALL_PATH="$INSTALL_DIR/ssutil"

# Check if /usr/local/bin exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    print_info "Creating $INSTALL_DIR directory..."
    sudo mkdir -p "$INSTALL_DIR"
fi

# Copy script to /usr/local/bin
print_info "Installing ssutil to $INSTALL_PATH..."
sudo cp "$SCRIPT_SOURCE" "$INSTALL_PATH"
sudo chmod +x "$INSTALL_PATH"

# Verify installation
if [[ -f "$INSTALL_PATH" ]]; then
    print_success "ssutil installed successfully!"
    echo ""
    print_info "You can now run 'ssutil' from any Simplicity Studio solution directory"
    echo ""
    echo "Try it:"
    echo "  cd /path/to/YourSimplicitySolution"
    echo "  ssutil --help"
    echo ""

    # Check if /usr/local/bin is in PATH
    if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
        print_warning "/usr/local/bin is not in your PATH"
        echo ""
        echo "Add this to your ~/.zshrc or ~/.bash_profile:"
        echo "  export PATH=\"/usr/local/bin:\$PATH\""
        echo ""
    fi
else
    print_error "Installation failed"
    exit 1
fi

# Cleanup temporary directory if used
if [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
