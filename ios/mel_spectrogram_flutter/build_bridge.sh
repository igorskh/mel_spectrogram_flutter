#!/bin/bash
set -e

BRIDGE_DIR="$(dirname "$0")/Sources/MelSpectrogramBridge"
BUILD_DIR="$(dirname "$0")/build/MelSpectrogramBridge"

mkdir -p "$BUILD_DIR"

# Compile Objective-C++ files
clang -c -fobjc-arc -fmodules -x objective-c++ \
    -I"$BRIDGE_DIR" \
    -o "$BUILD_DIR/MelSpectrogramBridge.o" \
    "$BRIDGE_DIR/MelSpectrogramBridge.mm"

# Create static library
ar rcs "$BUILD_DIR/libMelSpectrogramBridge.a" "$BUILD_DIR/MelSpectrogramBridge.o"

echo "Bridge library built successfully"
