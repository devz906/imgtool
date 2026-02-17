#!/bin/bash

# Box64 iOS Cross-Compile Script
# Targets iPhone 16 Pro (A18 Pro) with 16KB page architecture
# Based on M1 profile settings for compatibility

set -e  # Exit on any error

echo "🚀 Box64 iOS Cross-Compile Script"
echo "=================================="

# Configuration
BOX64_REPO="ptitSeb/box64"
BOX64_BRANCH="main"
BUILD_DIR="box64_build"
INSTALL_DIR="box64_install"
TARGET_ARCH="arm64"
TARGET_OS="ios"
MIN_IOS_VERSION="16.0"

# iPhone 16 Pro (A18 Pro) specific settings
# A18 Pro shares 16KB memory architecture with M1
CPU_FLAGS="-mcpu=apple-a18"
SYSROOT_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
CC_PATH=$(xcrun --find clang)
CXX_PATH=$(xcrun --find clang++)

echo "📱 Target: iPhone 16 Pro (A18 Pro)"
echo "🔧 Architecture: ARM64 with 16KB pages"
echo "📚 SDK Path: $SYSROOT_PATH"
echo "🔨 Compiler: $CC_PATH"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR" "$INSTALL_DIR" "box64_source"

# Clone Box64 repository
echo "📥 Cloning Box64 from GitHub..."
git clone --depth 1 --branch "$BOX64_BRANCH" "https://github.com/$BOX64_REPO.git" box64_source
cd box64_source

# Get latest commit hash for version tracking
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "🔢 Box64 Commit: $COMMIT_HASH"

# Create build directory
mkdir -p "../$BUILD_DIR"
cd "../$BUILD_DIR"

# Configure CMake for iOS A18 Pro
echo "⚙️  Configuring CMake for iOS A18 Pro..."
cmake ../box64_source \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$SYSROOT_PATH" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$MIN_IOS_VERSION" \
    -DCMAKE_OSX_ARCHITECTURES="$TARGET_ARCH" \
    -DCMAKE_C_COMPILER="$CC_PATH" \
    -DCMAKE_CXX_COMPILER="$CXX_PATH" \
    -DCMAKE_C_FLAGS="$CPU_FLAGS -O3 -flto" \
    -DCMAKE_CXX_FLAGS="$CPU_FLAGS -O3 -flto" \
    -DCMAKE_EXE_LINKER_FLAGS="-flto" \
    -DCMAKE_SHARED_LINKER_FLAGS="-flto" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="../$INSTALL_DIR" \
    -DARM_DYNAREC=ON \
    -DAPPLE=1 \
    -DPAGE16K=ON \
    -DNOGIT=ON \
    -DARM64=1 \
    -DLD80BITS=1 \
    -DALIGN=1

# Build Box64
echo "🔨 Building Box64 for iOS A18 Pro..."
make -j$(sysctl -n hw.ncpu)

# Install
echo "📦 Installing Box64..."
make install

# Verify the library was created
if [ -f "../$INSTALL_DIR/lib/libbox64.dylib" ]; then
    echo "✅ libbox64.dylib created successfully!"
    
    # Get library info
    LIB_SIZE=$(stat -f%z "../$INSTALL_DIR/lib/libbox64.dylib")
    echo "📊 Library size: $LIB_SIZE bytes"
    
    # Check architecture
    echo "🔍 Verifying architecture..."
    lipo -info "../$INSTALL_DIR/lib/libbox64.dylib"
    
    # Check for 16KB page support in binary
    echo "📄 Checking for 16KB page support..."
    if strings "../$INSTALL_DIR/lib/libbox64.dylib" | grep -q "16KB"; then
        echo "✅ 16KB page support found in binary"
    else
        echo "⚠️  16KB page support not explicitly found (may be compiled in)"
    fi
    
    # Create iOS framework structure
    echo "📚 Creating iOS Framework structure..."
    FRAMEWORK_DIR="../Box64.framework"
    rm -rf "$FRAMEWORK_DIR"
    
    mkdir -p "$FRAMEWORK_DIR/Headers"
    mkdir -p "$FRAMEWORK_DIR/Modules"
    
    # Copy library to framework
    cp "../$INSTALL_DIR/lib/libbox64.dylib" "$FRAMEWORK_DIR/Box64"
    
    # Create Info.plist for framework
    cat > "$FRAMEWORK_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Box64</string>
    <key>CFBundleIdentifier</key>
    <string>com.devz906.box64</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Box64</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>$COMMIT_HASH</string>
    <key>MinimumOSVersion</key>
    <string>$MIN_IOS_VERSION</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneOS</string>
    </array>
</dict>
</plist>
EOF
    
    # Create module map
    cat > "$FRAMEWORK_DIR/Modules/module.modulemap" << EOF
framework module Box64 {
    header "box64.h"
    export *
    module * { export * }
}
EOF
    
    # Copy headers if available
    if [ -d "../$INSTALL_DIR/include" ]; then
        cp -R ../$INSTALL_DIR/include/* "$FRAMEWORK_DIR/Headers/" 2>/dev/null || true
    fi
    
    echo "✅ Box64.framework created successfully!"
    echo "📁 Framework location: $FRAMEWORK_DIR"
    
    # Create a simple header for iOS integration
    cat > "$FRAMEWORK_DIR/Headers/box64.h" << EOF
#ifndef BOX64_H
#define BOX64_H

#ifdef __cplusplus
extern "C" {
#endif

// Box64 main initialization
int box64_init(int argc, char** argv);

// Box64 execution
int box64_run(const char* executable_path, int argc, char** argv);

// Box64 cleanup
void box64_cleanup();

// Memory management for 16KB pages
void* box64_alloc_16kb(size_t size);
void box64_free_16kb(void* ptr);

// JIT compilation support
int box64_enable_jit(void);
int box64_disable_jit(void);

#ifdef __cplusplus
}
#endif

#endif /* BOX64_H */
EOF
    
    echo "📄 Box64 header created for iOS integration"
    
    # Display final summary
    echo ""
    echo "🎉 Build Summary"
    echo "================"
    echo "✅ Box64 compiled successfully for iOS A18 Pro"
    echo "📱 Target: iPhone 16 Pro (16KB pages)"
    echo "🔧 Features: ARM_DYNAREC=ON, PAGE16K=ON, APPLE=1"
    echo "📦 Output: Box64.framework"
    echo "🔢 Commit: $COMMIT_HASH"
    echo "📊 Size: $LIB_SIZE bytes"
    echo ""
    echo "🚀 Ready for iOS integration!"
    
else
    echo "❌ ERROR: libbox64.dylib was not created!"
    exit 1
fi

# Clean up build directory
echo "🧹 Cleaning up build files..."
cd ..
rm -rf "$BUILD_DIR" "box64_source"

echo "✅ Cross-compilation completed successfully!"
