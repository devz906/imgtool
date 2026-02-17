# IMGTool - Box64 Environment for iOS

A SwiftUI iOS application designed to host a Box64 execution environment with JIT capabilities.

## Features

- **JIT Environment Initialization**: Uses ptrace to signal debugging mode for iOS JIT activation via SideStore
- **Box64 Integration**: Cross-compiled Box64 for iOS A18 Pro with 16KB page optimization
- **16KB Page Size Support**: Optimized for iPhone 16 Pro (A18 Pro) memory architecture
- **Memory Management**: Executable memory allocation for dynamic code generation
- **Automated Compilation**: Shell script and GitHub Actions for Box64 cross-compilation

## Requirements

- iOS 16.0+
- SideStore for JIT entitlements
- ARM64 device (iPhone/iPad)
- macOS with Xcode (for compilation)

## Quick Start

### 1. Compile Box64 for iOS

```bash
# Clone and compile Box64 for iPhone 16 Pro
./compile_engine.sh
```

### 2. Integration

The script generates `Box64.framework` ready for iOS integration.

### 3. Install via SideStore

Install the app with proper JIT entitlements.

## Compilation

### Automated Script

The `compile_engine.sh` script handles:

- **Repository Management**: Clones latest Box64 from GitHub
- **Cross-Compilation**: Targets iOS A18 Pro with specific flags
- **Framework Creation**: Generates iOS-ready framework
- **Verification**: Validates architecture and page size support

### Key Configuration

- **Target**: iPhone 16 Pro (A18 Pro)
- **Architecture**: ARM64 with 16KB pages
- **CMake Flags**: `-DARM_DYNAREC=ON -DAPPLE=1 -DPAGE16K=ON`
- **Compiler**: Apple Clang with A18 Pro optimizations

### Build Artifacts

- `Box64.framework/` - iOS framework
- `libbox64.dylib` - Dynamic library
- `box64.h` - C header for integration

## Entitlements

The app includes the following entitlements in `WinlatoriOS.entitlements`:

- `com.apple.security.get-task-allow`: Allows task inspection
- `com.apple.security.cs.allow-jit`: Enables JIT compilation
- `com.apple.developer.kernel.increased-memory-limit`: Increased memory limit for emulation

## Architecture

### JITManager
- Objective-C++ bridge for JIT initialization
- ptrace integration for iOS JIT activation
- 16KB page size validation
- Box64 environment integration

### SwiftUI Interface
- Real-time status display
- JIT and Box64 initialization controls
- System information display
- Environment reset functionality

### Box64 Integration
- Cross-compiled for iOS A18 Pro
- 16KB page size optimization
- ARM64 dynamic recompilation
- Memory management utilities

## Usage

1. **Compile Box64**: Run `./compile_engine.sh` to generate the framework
2. **Install App**: Install via SideStore with proper entitlements
3. **Initialize JIT**: Launch app and tap "Initialize JIT Environment"
4. **Load Box64**: Framework is automatically loaded and ready
5. **Run Executables**: Use Box64 to run x86-64 Linux executables

## Development

### Current Implementation
- JIT environment setup with ptrace
- Box64 cross-compilation for iOS
- 16KB page size optimization
- SwiftUI interface for control
- Automated build pipeline

### Future Development
- Complete x86-64 executable loading
- Dynamic linking support
- Linux syscall compatibility layer
- Performance optimization
- Advanced UI features

## Build Automation

GitHub Actions automatically compiles Box64 when:
- Script changes are pushed
- Pull requests are created
- Manual workflow dispatch

Artifacts are uploaded as:
- `Box64-iOS-Framework` - Ready-to-use framework
- `Box64-iOS-Zip` - Compressed framework

## Documentation

- [COMPILE.md](./COMPILE.md) - Detailed compilation guide
- [GitHub Actions](./.github/workflows/compile-box64.yml) - Automated build pipeline

## License

MIT License - see LICENSE file for details
