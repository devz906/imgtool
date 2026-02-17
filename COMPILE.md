# Box64 iOS Compilation Guide

## Overview

The `compile_engine.sh` script cross-compiles Box64 for iOS, specifically targeting the iPhone 16 Pro (A18 Pro) with its 16KB memory architecture.

## Prerequisites

- macOS with Xcode installed
- iOS SDK (latest version)
- Git
- CMake (installed via Xcode Command Line Tools)

## Usage

### Quick Start

```bash
# Make the script executable (macOS/Linux)
chmod +x compile_engine.sh

# Run the compilation
./compile_engine.sh
```

### Windows (PowerShell)

```powershell
# Set execution permissions
icacls compile_engine.sh /grant "Everyone:(RX)"

# Run via Git Bash or WSL
./compile_engine.sh
```

## Configuration

### Target Specifications

- **Device**: iPhone 16 Pro (A18 Pro)
- **Architecture**: ARM64
- **Page Size**: 16KB (optimized for A18 Pro)
- **Minimum iOS**: 16.0
- **Compiler**: Apple Clang with A18 Pro optimizations

### CMake Flags

| Flag | Value | Purpose |
|------|-------|---------|
| `-DARM_DYNAREC=ON` | Enabled | ARM dynamic recompilation |
| `-DCMAKE_OSX_SYSROOT=iphoneos` | iOS SDK | Cross-compilation target |
| `-DAPPLE=1` | Enabled | Apple-specific optimizations |
| `-DPAGE16K=ON` | Enabled | 16KB page size support |
| `-DARM64=1` | Enabled | ARM64 architecture |
| `-DLD80BITS=1` | Enabled | 80-bit long double support |
| `-DALIGN=1` | Enabled | Memory alignment optimizations |

### Compiler Optimizations

- **CPU**: `-mcpu=apple-a18` (A18 Pro specific)
- **Optimization**: `-O3 -flto` (Link-time optimization)
- **System**: iOS SDK with deployment target 16.0

## Output

The script generates:

1. **Box64.framework** - iOS framework for easy integration
2. **libbox64.dylib** - Dynamic library
3. **box64.h** - C header for iOS integration
4. **Info.plist** - Framework metadata

### Framework Structure

```
Box64.framework/
├── Box64              # Main library (libbox64.dylib)
├── Info.plist         # Framework metadata
├── Headers/
│   └── box64.h        # C header file
└── Modules/
    └── module.modulemap # Swift module map
```

## Integration

### Swift Integration

Add the `Box64.framework` to your Xcode project and import:

```swift
import Box64

// Initialize Box64
let result = box64_init(0, nil)

// Run x86-64 executable
let executable = "/path/to/linux executable"
let args: [UnsafeMutablePointer<CChar>?] = [...]
box64_run(executable, Int32(args.count), args)
```

### Objective-C Integration

```objc
#import <Box64/box64.h>

// Initialize
int result = box64_init(0, NULL);

// Run
box64_run("/path/to/executable", argc, argv);
```

## Features

### JIT Support

The compiled Box64 includes:
- Dynamic recompilation for ARM64
- JIT compilation with 16KB page optimization
- Memory management for large page sizes

### Memory Architecture

- **16KB Pages**: Optimized for A18 Pro memory architecture
- **Large Memory Support**: Increased memory limits via entitlements
- **Efficient Translation**: ARM64 to x86-64 dynamic translation

### Performance Optimizations

- **Link-Time Optimization**: `-flto` for better performance
- **A18 Pro Tuning**: Specific CPU optimizations
- **ARM Dynarec**: Dynamic recompilation for ARM64

## Troubleshooting

### Common Issues

1. **SDK Not Found**: Ensure Xcode and iOS SDK are installed
2. **Permission Denied**: Make script executable with `chmod +x`
3. **Compilation Errors**: Check Xcode version compatibility

### Debug Information

The script provides detailed logging:
- Repository and commit information
- SDK and compiler paths
- Build configuration
- Output verification

### Manual Verification

```bash
# Check architecture
lipo -info Box64.framework/Box64

# Check for 16KB support
strings Box64.framework/Box64 | grep 16KB

# Verify framework structure
codesign -dv Box64.framework
```

## Automated Build

The GitHub Actions workflow (`.github/workflows/compile-box64.yml`) automatically:

1. Sets up macOS environment
2. Configures Xcode and iOS SDK
3. Runs the compilation script
4. Verifies the output
5. Uploads artifacts

### Workflow Triggers

- Push to main branch (when script changes)
- Pull requests to main branch
- Manual workflow dispatch

## Notes

- The script is based on M1 profile settings for A18 Pro compatibility
- 16KB page architecture is critical for A18 Pro performance
- JIT requires proper entitlements for runtime execution
- Framework is signed for iOS distribution

## Support

For issues with:
- **Compilation**: Check Xcode and iOS SDK installation
- **Runtime**: Verify entitlements and JIT permissions
- **Performance**: Ensure 16KB page support is enabled
