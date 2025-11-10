#!/bin/bash
################################################################################
# ssutil - Simplicity Studio Utility
# A unified CLI build and flash tool for Silicon Labs Simplicity Studio projects
#
# Author: Cris Kedmenec (github.com/ckedmenec)
# License: MIT
# Version: 1.0.0
################################################################################

set -e  # Exit on error

# Colors for output (will be set after parsing --no-color flag)
RED=''
GREEN=''
YELLOW=''
BLUE=''
NC=''

################################################################################
# Project Configuration
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDER="/Applications/Simplicity Studio.app/Contents/Eclipse/developer/adapter_packs/commander/Commander.app/Contents/MacOS/commander"

# Auto-detect project directories if not specified
auto_detect_project() {
    local found_projects=()
    local found_bootloader=""

    # Search for Simplicity Studio 5 projects (GNU ARM build folders)
    while IFS= read -r -d '' dir; do
        local parent_dir=$(dirname "$dir")
        local dir_name=$(basename "$parent_dir")

        # Skip if directory name contains "bootloader" (case insensitive)
        if [[ ! "$dir_name" =~ [Bb]ootloader ]]; then
            found_projects+=("$parent_dir")
        fi
    done < <(find "$SCRIPT_DIR" -maxdepth 2 -type d -name "GNU ARM*" -print0 2>/dev/null)

    # Search for Simplicity Studio 6 projects (cmake_gcc build folders)
    while IFS= read -r -d '' dir; do
        local parent_dir=$(dirname "$dir")
        local dir_name=$(basename "$parent_dir")

        # Skip if directory name contains "bootloader" or "_cmake" (case insensitive)
        if [[ ! "$dir_name" =~ [Bb]ootloader ]] && [[ ! "$dir_name" =~ _cmake ]]; then
            found_projects+=("$parent_dir")
        fi
    done < <(find "$SCRIPT_DIR" -maxdepth 2 -type d -name "cmake_gcc" -print0 2>/dev/null)

    # Search for bootloader directory (SS5: has GNU ARM folder, SS6: has cmake_gcc folder)
    while IFS= read -r -d '' dir; do
        local parent_dir=$(dirname "$dir")
        local dir_name=$(basename "$parent_dir")

        if [[ "$dir_name" =~ [Bb]ootloader ]]; then
            found_bootloader="$parent_dir"
            break
        fi
    done < <(find "$SCRIPT_DIR" -maxdepth 2 -type d \( -name "GNU ARM*" -o -name "cmake_gcc" \) -print0 2>/dev/null)

    # Set project directory
    if [[ ${#found_projects[@]} -eq 1 ]]; then
        echo "${found_projects[0]}"
    elif [[ ${#found_projects[@]} -gt 1 ]]; then
        # Multiple projects found, return first non-bootloader one
        echo "${found_projects[0]}"
    else
        echo ""
    fi

    # Return bootloader directory via second output
    echo "$found_bootloader"
}

# Initialize project and bootloader names from environment or auto-detect
PROJECT_NAME="${PROJECT_NAME:-}"
BOOTLOADER_NAME="${BOOTLOADER_NAME:-}"
AUTO_DETECTED_PROJECT=false
AUTO_DETECTED_BOOTLOADER=false

# Paths (will be updated after auto-detection or argument parsing)
APP_DIR=""
APP_BUILD_DIR=""
BOOTLOADER_DIR=""
BOOTLOADER_BUILD_DIR=""

# Parse arguments
ERASE=false
CLEAN=false
BUILD_ONLY=false
FLASH_ONLY=false
NO_COLOR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --erase|-e)
            ERASE=true
            shift
            ;;
        --clean|-c)
            CLEAN=true
            shift
            ;;
        --build-only|-B)
            BUILD_ONLY=true
            shift
            ;;
        --flash-only|-F)
            FLASH_ONLY=true
            shift
            ;;
        --no-color)
            NO_COLOR=true
            shift
            ;;
        --project|-p)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --bootloader|-b)
            BOOTLOADER_NAME="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -e, --erase              Mass erase device and flash bootloader first"
            echo "  -c, --clean              Clean build before compiling"
            echo "  -B, --build-only         Build only (skip flashing and device operations)"
            echo "  -F, --flash-only         Flash only (skip building, use existing binaries)"
            echo "  -p, --project <name>     Specify project directory name (auto-detected if not provided)"
            echo "  -b, --bootloader <name>  Specify bootloader directory name (auto-detected if not provided)"
            echo "  -h, --help               Show this help message"
            echo ""
            echo "Auto-Detection:"
            echo "  The script automatically finds projects by searching for directories containing"
            echo "  'GNU ARM*' build folders. Directories with 'bootloader' in the name are treated"
            echo "  as bootloader projects, others as application projects."
            echo ""
            echo "Examples:"
            echo "  $0                                    # Auto-detect, build and flash (default)"
            echo "  $0 --clean                            # Auto-detect, clean build and flash"
            echo "  $0 --build-only                       # Build only (no flash)"
            echo "  $0 --flash-only                       # Flash only (no build)"
            echo "  $0 -B -e                              # Build bootloader and app (no flash/erase)"
            echo "  $0 -B -c                              # Clean build only (no flash)"
            echo "  $0 -F                                 # Quick reflash of existing binary"
            echo "  $0 --erase                            # Mass erase, build and flash bootloader+app"
            echo "  $0 -c -e                              # Clean build with mass erase and flash"
            echo "  $0 --project MyProject                # Build and flash specific project"
            echo "  $0 -p MyProject -b MyBootloader -c    # Specify both project and bootloader"
            echo ""
            echo "Environment Variables:"
            echo "  PROJECT_NAME      Override project directory name (skips auto-detection)"
            echo "  BOOTLOADER_NAME   Override bootloader directory name (skips auto-detection)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Initialize colors (after parsing --no-color flag)
if [[ "$NO_COLOR" == false ]] && [[ -t 1 ]] && command -v tput &> /dev/null && tput setaf 1 &> /dev/null; then
    # Terminal supports colors and user didn't disable them
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
fi

# Validate flag combinations
if [[ "$BUILD_ONLY" == true ]] && [[ "$FLASH_ONLY" == true ]]; then
    echo "ERROR: Cannot use --build-only and --flash-only together"
    echo "Use --help for usage information"
    exit 1
fi

if [[ "$FLASH_ONLY" == true ]] && [[ "$CLEAN" == true ]]; then
    echo "ERROR: Cannot use --flash-only with --clean (nothing to clean without building)"
    echo "Use --help for usage information"
    exit 1
fi

# Auto-detect projects if not already specified
if [[ -z "$PROJECT_NAME" ]] || [[ -z "$BOOTLOADER_NAME" ]]; then
    # Read detection results line by line
    detection_output=$(auto_detect_project)
    detected_app=$(echo "$detection_output" | sed -n '1p')
    detected_bootloader=$(echo "$detection_output" | sed -n '2p')

    if [[ -z "$PROJECT_NAME" ]]; then
        if [[ -n "$detected_app" ]]; then
            APP_DIR="$detected_app"
            PROJECT_NAME=$(basename "$APP_DIR")
            AUTO_DETECTED_PROJECT=true
        else
            print_error "No project directory found! Directory must contain 'GNU ARM*' folder."
            exit 1
        fi
    fi

    if [[ -z "$BOOTLOADER_NAME" ]]; then
        if [[ -n "$detected_bootloader" ]]; then
            BOOTLOADER_DIR="$detected_bootloader"
            BOOTLOADER_NAME=$(basename "$BOOTLOADER_DIR")
            AUTO_DETECTED_BOOTLOADER=true
        fi
    fi
fi

# Set paths based on final project/bootloader names
if [[ -z "$APP_DIR" ]]; then
    APP_DIR="$SCRIPT_DIR/$PROJECT_NAME"
fi

# Detect build system (SS5 uses GNU ARM, SS6 uses cmake_gcc)
if [[ -d "$APP_DIR/cmake_gcc/build" ]]; then
    # Simplicity Studio 6 (CMake/Ninja)
    APP_BUILD_DIR="$APP_DIR/cmake_gcc/build"
    BUILD_SYSTEM="cmake"
elif [[ -d "$APP_DIR/GNU ARM v12.2.1 - Default" ]]; then
    # Simplicity Studio 5 (GNU Make)
    APP_BUILD_DIR="$APP_DIR/GNU ARM v12.2.1 - Default"
    BUILD_SYSTEM="make"
else
    # Try to find any GNU ARM directory
    APP_BUILD_DIR=$(find "$APP_DIR" -maxdepth 1 -type d -name "GNU ARM*" | head -1)
    if [[ -z "$APP_BUILD_DIR" ]]; then
        APP_BUILD_DIR="$APP_DIR/GNU ARM v12.2.1 - Default"
    fi
    BUILD_SYSTEM="make"
fi

# Set bootloader paths
if [[ -z "$BOOTLOADER_DIR" ]] && [[ -n "$BOOTLOADER_NAME" ]]; then
    BOOTLOADER_DIR="$SCRIPT_DIR/$BOOTLOADER_NAME"
fi

if [[ -n "$BOOTLOADER_DIR" ]]; then
    # Detect bootloader build system
    if [[ -d "$BOOTLOADER_DIR/cmake_gcc/build" ]]; then
        BOOTLOADER_BUILD_DIR="$BOOTLOADER_DIR/cmake_gcc/build"
        BOOTLOADER_BUILD_SYSTEM="cmake"
    elif [[ -d "$BOOTLOADER_DIR/GNU ARM v12.2.1 - Default" ]]; then
        BOOTLOADER_BUILD_DIR="$BOOTLOADER_DIR/GNU ARM v12.2.1 - Default"
        BOOTLOADER_BUILD_SYSTEM="make"
    else
        BOOTLOADER_BUILD_DIR=$(find "$BOOTLOADER_DIR" -maxdepth 1 -type d -name "GNU ARM*" | head -1)
        if [[ -z "$BOOTLOADER_BUILD_DIR" ]]; then
            BOOTLOADER_BUILD_DIR="$BOOTLOADER_DIR/GNU ARM v12.2.1 - Default"
        fi
        BOOTLOADER_BUILD_SYSTEM="make"
    fi
fi

################################################################################
# Functions
################################################################################

print_header() {
    printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${BLUE}%s${NC}\n" "$1"
    printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    printf "${GREEN}✅ %s${NC}\n" "$1"
}

print_error() {
    printf "${RED}❌ %s${NC}\n" "$1"
}

print_info() {
    printf "${YELLOW}ℹ️  %s${NC}\n" "$1"
}

build_project() {
    local project_name=$1
    local build_dir=$2
    local build_system=$3  # "make" or "cmake"

    print_header "Building $project_name"

    if [[ ! -d "$build_dir" ]]; then
        print_error "Build directory not found: $build_dir"
        exit 1
    fi

    cd "$build_dir"

    # Clean build artifacts if requested
    if [[ "$CLEAN" == true ]]; then
        print_info "Cleaning previous build..."
        if [[ "$build_system" == "cmake" ]]; then
            ninja clean > /dev/null 2>&1 || cmake --build . --target clean > /dev/null 2>&1 || true
        else
            make clean > /dev/null 2>&1 || true
        fi
    else
        print_info "Performing incremental build (use --clean for full rebuild)..."
    fi

    # Build with appropriate build system
    print_info "Building..."

    # Use 'script' to capture output while preserving colors
    # The -q flag suppresses "Script started/done" messages
    # This gives us both colored terminal output AND a saved log file
    if [[ "$build_system" == "cmake" ]]; then
        # Simplicity Studio 6 uses CMake/Ninja build system
        # Try to find ninja in common locations if not in PATH
        NINJA_CMD="ninja"
        if ! command -v ninja &> /dev/null; then
            # Check Silabs tools directory
            SILABS_NINJA=$(find /Users/cris/.silabs/slt/installs -name "ninja" -type f 2>/dev/null | head -1)
            if [[ -n "$SILABS_NINJA" ]]; then
                NINJA_CMD="$SILABS_NINJA"
            else
                # Fall back to cmake --build which works with any generator
                print_info "Ninja not found, using cmake --build instead..."
                if ! script -q build.log cmake --build . --parallel $(sysctl -n hw.ncpu); then
                    print_error "$project_name build failed!"
                    echo ""
                    echo "Last 50 lines of build log:"
                    tail -50 build.log
                    exit 1
                fi
                # Skip the ninja command below
                NINJA_CMD=""
            fi
        fi

        # Run ninja if we found it
        if [[ -n "$NINJA_CMD" ]]; then
            if ! script -q build.log "$NINJA_CMD" -j$(sysctl -n hw.ncpu); then
                print_error "$project_name build failed!"
                echo ""
                echo "Last 50 lines of build log:"
                tail -50 build.log
                exit 1
            fi
        fi
    else
        # Simplicity Studio 5 uses Make
        if ! script -q build.log make -j$(sysctl -n hw.ncpu) all; then
            print_error "$project_name build failed!"
            echo ""
            echo "Last 50 lines of build log:"
            tail -50 build.log
            exit 1
        fi
    fi

    # Verify build actually completed by checking for success indicators
    # Note: CMake/Ninja may not have "DONE" message, so we check for binary artifacts
    if [[ "$build_system" == "cmake" ]]; then
        # For CMake builds, check if binary was created
        if ! find . -name "*.s37" -o -name "*.hex" | grep -q .; then
            print_error "$project_name build may not have completed properly!"
            echo ""
            echo "Warning: Could not find binary artifacts (.s37 or .hex files)"
            echo "Last 30 lines of build log:"
            tail -30 build.log
            # Don't exit, continue anyway
        fi
    else
        # For Make builds, check for DONE message
        if ! grep -q "DONE" build.log; then
            print_error "$project_name build did not complete properly!"
            echo ""
            echo "Build output did not contain completion message."
            echo "Last 30 lines of build log:"
            tail -30 build.log
            exit 1
        fi
    fi

    # Show final build summary
    echo ""
    echo "Build summary:"
    grep -A 3 "Ram usage\|Flash usage" build.log || true

    print_success "$project_name built successfully"
    return 0
}

flash_file() {
    local file=$1
    local description=$2

    print_info "Flashing $description..."

    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        exit 1
    fi

    # Show artifact timestamp
    print_info "Artifact timestamp: $(stat -f %Sm -t '%Y-%m-%d %H:%M:%S' "$file")"

    # Warn if file seems old (only if clean build was NOT requested)
    if [[ "$CLEAN" == false ]]; then
        local file_age=$(($(date +%s) - $(stat -f %m "$file")))
        if [[ $file_age -gt 300 ]]; then
            printf "${YELLOW}⚠️  Warning: Artifact is more than 5 minutes old (incremental build)${NC}\n"
            printf "${YELLOW}   Consider using --clean if you expect changes${NC}\n"
        fi
    fi

    if "$COMMANDER" flash "$file" 2>&1 | tee flash.log; then
        print_success "$description flashed successfully"
    else
        print_error "Failed to flash $description"
        cat flash.log
        exit 1
    fi
}

mass_erase() {
    print_header "Mass Erasing Device"

    print_info "Erasing flash memory..."
    if "$COMMANDER" device masserase 2>&1; then
        print_success "Device erased successfully"
    else
        print_error "Mass erase failed!"
        exit 1
    fi
}

reset_device() {
    print_info "Resetting device..."
    if "$COMMANDER" device reset 2>&1; then
        print_success "Device reset successfully"
    else
        print_error "Device reset failed!"
        exit 1
    fi
}

################################################################################
# Main Script
################################################################################

echo ""
if [[ "$BUILD_ONLY" == true ]]; then
    print_header "Simplicity Studio - Build Only"
elif [[ "$FLASH_ONLY" == true ]]; then
    print_header "Simplicity Studio - Flash Only"
else
    print_header "Simplicity Studio - Build & Flash"
fi
echo ""

# Show detected project info
if [[ "$AUTO_DETECTED_PROJECT" == true ]]; then
    print_info "Project: $PROJECT_NAME (auto-detected)"
else
    print_info "Project: $PROJECT_NAME"
fi

if [[ "$ERASE" == true ]]; then
    if [[ -n "$BOOTLOADER_NAME" ]]; then
        if [[ "$AUTO_DETECTED_BOOTLOADER" == true ]]; then
            print_info "Bootloader: $BOOTLOADER_NAME (auto-detected)"
        else
            print_info "Bootloader: $BOOTLOADER_NAME"
        fi
    else
        print_info "Bootloader: Not found - skipping bootloader"
    fi
fi

if [[ "$BUILD_ONLY" == true ]]; then
    print_info "Mode: Build only (skipping flash)"
elif [[ "$FLASH_ONLY" == true ]]; then
    print_info "Mode: Flash only (skipping build)"
fi
echo ""

# Check if commander exists (only if we need to flash)
if [[ "$BUILD_ONLY" == false ]] && [[ ! -f "$COMMANDER" ]]; then
    print_error "Commander not found at: $COMMANDER"
    exit 1
fi

# Mass erase if requested (only if not build-only mode)
if [[ "$ERASE" == true ]] && [[ "$BUILD_ONLY" == false ]]; then
    mass_erase
    echo ""
fi

# Build bootloader if erase flag is set (skip if flash-only mode)
if [[ "$ERASE" == true ]] && [[ "$FLASH_ONLY" == false ]]; then
    if [[ -n "$BOOTLOADER_NAME" ]]; then
        if [[ "$BUILD_ONLY" == true ]]; then
            print_header "Building Bootloader"
        else
            print_header "Building and Flashing Bootloader"
        fi
        build_project "Bootloader" "$BOOTLOADER_BUILD_DIR" "$BOOTLOADER_BUILD_SYSTEM"
        echo ""

        # Flash bootloader only if not in build-only mode
        if [[ "$BUILD_ONLY" == false ]]; then
            # Find bootloader artifacts
            BOOTLOADER_S37=$(find "$BOOTLOADER_BUILD_DIR" -name "*.s37" | head -1)
            if [[ -z "$BOOTLOADER_S37" ]]; then
                print_error "Bootloader .s37 file not found in $BOOTLOADER_BUILD_DIR"
                exit 1
            fi

            flash_file "$BOOTLOADER_S37" "Bootloader"
            echo ""
        fi
    fi
fi

# Flash bootloader if erase+flash-only mode
if [[ "$ERASE" == true ]] && [[ "$FLASH_ONLY" == true ]]; then
    if [[ -n "$BOOTLOADER_NAME" ]]; then
        print_header "Flashing Bootloader"

        # Find bootloader artifacts
        BOOTLOADER_S37=$(find "$BOOTLOADER_BUILD_DIR" -name "*.s37" | head -1)
        if [[ -z "$BOOTLOADER_S37" ]]; then
            print_error "Bootloader .s37 file not found in $BOOTLOADER_BUILD_DIR"
            print_error "No pre-built bootloader binary found. Build first or remove --flash-only flag."
            exit 1
        fi

        flash_file "$BOOTLOADER_S37" "Bootloader"
        echo ""
    fi
fi

# Build application (skip if flash-only mode)
if [[ "$FLASH_ONLY" == false ]]; then
    build_project "$PROJECT_NAME" "$APP_BUILD_DIR" "$BUILD_SYSTEM"
    echo ""
fi

# Flash application and reset device (only if not build-only mode)
if [[ "$BUILD_ONLY" == false ]]; then
    # Flash application
    print_header "Flashing Application"

    # Find application artifacts (.s37 or .hex)
    APP_S37=$(find "$APP_BUILD_DIR" -name "*.s37" | grep -v bootloader | head -1)
    if [[ -z "$APP_S37" ]]; then
        print_error "Application .s37 file not found in $APP_BUILD_DIR"
        if [[ "$FLASH_ONLY" == true ]]; then
            print_error "No pre-built application binary found. Build first or remove --flash-only flag."
        fi
        exit 1
    fi

    flash_file "$APP_S37" "Application"
    echo ""

    # Reset device
    print_header "Resetting Device"
    reset_device
    echo ""

    # Summary
    if [[ "$FLASH_ONLY" == true ]]; then
        print_header "Flash Complete"
        echo ""
        print_success "All flash operations completed successfully!"
        echo ""
        if [[ "$ERASE" == true ]]; then
            print_info "Flashed: Bootloader and Application (from pre-built binaries)"
        else
            print_info "Flashed: Application (from pre-built binary)"
        fi
    else
        print_header "Flash Complete"
        echo ""
        print_success "All operations completed successfully!"
        echo ""
        print_info "Device has been reset and is now running the new firmware"
        echo ""

        if [[ "$ERASE" == true ]]; then
            print_info "Note: Device was mass erased - you may need to re-commission"
        fi
    fi
else
    # Build-only mode summary
    print_header "Build Complete"
    echo ""
    print_success "All build operations completed successfully!"
    echo ""
    if [[ "$ERASE" == true ]]; then
        print_info "Built: Bootloader and Application"
    else
        print_info "Built: Application"
    fi
fi

echo ""
