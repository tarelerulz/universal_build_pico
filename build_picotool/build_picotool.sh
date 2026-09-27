#!/usr/bin/env bash
# build_picotool.sh
#
# Builds picotool from source on Linux or Windows (MSYS2).
# USB support is disabled — only UF2 conversion is needed.
# Run this once before building the firmware.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PICOTOOL_SRC="$SCRIPT_DIR/picotool_src"
BUILD_DIR="$SCRIPT_DIR/picotool_build"
FIRMWARE_DIR="$SCRIPT_DIR/../firmware"
PICOTOOL_REV="25aa087b2c517b4901874a99536e869d4d27b678"
JOBS="${JOBS:-2}"

# Detect Windows (MSYS2/mingw) vs Linux
if [[ "${OSTYPE:-}" == "msys" || "${OSTYPE:-}" == "mingw"* || "${OSTYPE:-}" == "cygwin" ]]; then
    PLATFORM="windows"
    EXE=".exe"
else
    PLATFORM="linux"
    EXE=""
fi

echo "=== Building picotool for $PLATFORM ==="
echo

# ---- dependency checks ----
need_tool() {
    local cmd="$1"
    local hint="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: '$cmd' not found."
        echo "       $hint"
        exit 1
    fi
}

need_tool git    "Install git  ->  https://git-scm.com/downloads"
need_tool cmake  "Install cmake -> https://cmake.org/download/  (or: pacman -S mingw-w64-ucrt-x86_64-cmake)"
need_tool python3 "Install Python 3 -> https://www.python.org/downloads/  (or: pacman -S mingw-w64-ucrt-x86_64-python)"

if ! command -v g++ >/dev/null 2>&1; then
    echo "ERROR: C++ compiler (g++) not found."
    if [[ "$PLATFORM" == "windows" ]]; then
        echo "       In MSYS2 UCRT64: pacman -S mingw-w64-ucrt-x86_64-gcc"
    else
        echo "       On Linux: sudo apt install build-essential"
    fi
    exit 1
fi

# ---- clone picotool ----
if [ ! -d "$PICOTOOL_SRC" ]; then
    echo "Cloning picotool from GitHub..."
    git clone --no-checkout https://github.com/raspberrypi/picotool.git "$PICOTOOL_SRC"
    git -C "$PICOTOOL_SRC" checkout --detach "$PICOTOOL_REV"
    echo
else
    echo "picotool source already present — skipping clone."
    echo
fi

if [[ "$(git -C "$PICOTOOL_SRC" rev-parse HEAD)" != "$PICOTOOL_REV" ]]; then
    echo "Expected picotool commit $PICOTOOL_REV."
    echo "Existing checkout was preserved; use a separate checkout at that revision."
    exit 1
fi
if [[ -n "$(git -C "$PICOTOOL_SRC" status --porcelain)" ]]; then
    echo "picotool checkout has local changes; preserve them before rebuilding."
    exit 1
fi

# ---- configure ----
echo "Configuring..."
cmake -S "$PICOTOOL_SRC" \
      -B "$BUILD_DIR" \
      -DCMAKE_BUILD_TYPE=Release \
      -DPICOTOOL_NO_LIBUSB=1

# ---- build ----
echo
echo "Building..."
cmake --build "$BUILD_DIR" --config Release -j"$JOBS"

# ---- find the binary ----
BUILT_BIN="$BUILD_DIR/picotool${EXE}"
if [ ! -f "$BUILT_BIN" ]; then
    BUILT_BIN="$(find "$BUILD_DIR" -name "picotool${EXE}" | head -1)"
fi
if [ -z "$BUILT_BIN" ] || [ ! -f "$BUILT_BIN" ]; then
    echo "ERROR: Could not find the built picotool binary."
    exit 1
fi

# ---- copy to firmware directory ----
echo
echo "Copying picotool to firmware/..."
cp "$BUILT_BIN" "$FIRMWARE_DIR/picotool${EXE}"

echo
echo "=== Done! ==="
echo "Binary: $FIRMWARE_DIR/picotool${EXE}"
echo
echo "You can now build the firmware by running 'make' in the project root."
