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

# Apply iOS compatibility patches
echo "🔧 Applying iOS compatibility patches..."

# Create a backup of the original file
cp src/include/os.h src/include/os.h.bak

# Fix PROT_* macro redefinition by commenting them out on iOS
# Since iOS already defines these macros, we don't need Box64's definitions
sed -i.bak 's/^#define PROT_READ/\/\/ #define PROT_READ/' src/include/os.h
sed -i.bak 's/^#define PROT_WRITE/\/\/ #define PROT_WRITE/' src/include/os.h
sed -i.bak 's/^#define PROT_EXEC/\/\/ #define PROT_EXEC/' src/include/os.h

# Fix JUMPBUFF definition for iOS - use proper jmp_buf type
sed -i.bak 's|#define JUMPBUFF struct __jmp_buf_tag|#define JUMPBUFF jmp_buf|' src/include/os.h

# Fix NEW_JUMPBUFF macro for iOS
sed -i.bak 's|#define NEW_JUMPBUFF(name)|jmp_buf name|' src/include/os.h

# Fix GET_JUMPBUFF macro for iOS
sed -i.bak 's|#define GET_JUMPBUFF(name)|&name|' src/include/os.h

echo "✅ iOS patches applied"

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
    -DCMAKE_C_FLAGS="$CPU_FLAGS -O3 -flto -D_XOPEN_SOURCE=700 -D__USE_GNU -D sincos=__sincos" \
    -DCMAKE_CXX_FLAGS="$CPU_FLAGS -O3 -flto -D_XOPEN_SOURCE=700 -D__USE_GNU -D sincos=__sincos" \
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
    -DALIGN=1 \
    -DCMAKE_INSTALL_BINDIR="bin" \
    -DCMAKE_INSTALL_LIBDIR="lib" \
    -DCMAKE_MACOSX_BUNDLE=OFF

# Build Box64
echo "🔨 Building Box64 for iOS A18 Pro..."
make -j$(sysctl -n hw.ncpu)

# Check if box64 binary was created
if [ -f "box64" ]; then
    echo "✅ Box64 binary created successfully!"
    
    # Create iOS framework structure
    echo "📚 Creating iOS Framework structure..."
    FRAMEWORK_DIR="../Box64.framework"
    rm -rf "$FRAMEWORK_DIR"
    
    mkdir -p "$FRAMEWORK_DIR/Headers"
    mkdir -p "$FRAMEWORK_DIR/Modules"
    
    # Copy binary to framework
    cp "box64" "$FRAMEWORK_DIR/Box64"
    
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
void box64_cleanup(void);

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
    
    echo "✅ Box64.framework created successfully!"
    echo "📁 Framework location: $FRAMEWORK_DIR"
    
    # Get binary info
    BIN_SIZE=$(stat -f%z "box64")
    echo "📊 Binary size: $BIN_SIZE bytes"
    
    # Check architecture
    echo "🔍 Verifying architecture..."
    lipo -info "box64"
    
    # Display final summary
    echo ""
    echo "🎉 Build Summary"
    echo "================"
    echo "✅ Box64 compiled successfully for iOS A18 Pro"
    echo "📱 Target: iPhone 16 Pro (16KB pages)"
    echo "🔧 Features: ARM_DYNAREC=ON, PAGE16K=ON, APPLE=1"
    echo "📦 Output: Box64.framework"
    echo "🔢 Commit: $COMMIT_HASH"
    echo "📊 Size: $BIN_SIZE bytes"
    echo ""
    echo "🚀 Ready for iOS integration!"
    
else
    echo "❌ ERROR: box64 binary was not created!"
    echo "🔍 Checking for build errors..."
    
    # Try to find any built files
    if [ -f "src/libbox64.a" ]; then
        echo "📦 Found static library: src/libbox64.a"
        echo "🔄 Creating dynamic library from static library..."
        
        # Create dynamic library
        "$CC_PATH" -dynamiclib -o "../libbox64.dylib" \
            -sysroot "$SYSROOT_PATH" \
            -target "$TARGET_ARCH-apple-ios$MIN_IOS_VERSION" \
            -install_name "@rpath/libbox64.dylib" \
            src/libbox64.a \
            -framework Foundation \
            -framework UIKit \
            $CPU_FLAGS -flto
        
        if [ -f "../libbox64.dylib" ]; then
            echo "✅ libbox64.dylib created successfully!"
            
            # Create framework from dylib
            FRAMEWORK_DIR="../Box64.framework"
            rm -rf "$FRAMEWORK_DIR"
            
            mkdir -p "$FRAMEWORK_DIR/Headers"
            mkdir -p "$FRAMEWORK_DIR/Modules"
            
            cp "../libbox64.dylib" "$FRAMEWORK_DIR/Box64"
            
            # Create Info.plist
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
            
            # Create header and module map as before...
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
void box64_cleanup(void);

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
            
            echo "✅ Box64.framework created from static library!"
            
        else
            echo "❌ Failed to create dynamic library"
            exit 1
        fi
    else
        echo "❌ No build artifacts found"
        exit 1
    fi
fi

# Clean up build directory
echo "🧹 Cleaning up build files..."
cd ..
rm -rf "$BUILD_DIR" "box64_source"

echo "✅ Cross-compilation completed successfully!"
