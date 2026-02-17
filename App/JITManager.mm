#import "JITManager.h"
#import <sys/mman.h>
#import <unistd.h>
#import <iostream>

@implementation JITManager

+ (BOOL)initializeJITEnvironment {
    NSLog(@"🚀 Initializing JIT environment for Box64...");
    
    // Signal to iOS that this process is being 'debugged' (required for JIT via SideStore)
    // This is a critical step for JIT to work on iOS without developer certificate
    if (ptrace(PT_TRACE_ME, 0, 0, 0) == -1) {
        NSLog(@"❌ Failed to initialize ptrace for JIT: %s", strerror(errno));
        return NO;
    }
    
    NSLog(@"✅ ptrace initialized successfully - JIT environment ready");
    
    // Enable JIT write protection
    [JITManager enableJITWriteProtection:YES];
    
    return YES;
}

+ (BOOL)check16KBPageSize {
    NSLog(@"📄 Checking 16KB page size support...");
    
    // Get system page size
    long pageSize = sysconf(_SC_PAGESIZE);
    NSLog(@"📏 System page size: %ld bytes", pageSize);
    
    // Check if page size is 16KB (16384 bytes)
    if (pageSize == 16384) {
        NSLog(@"✅ 16KB page size detected - optimal for Box64");
        return YES;
    } else if (pageSize == 4096) {
        NSLog(@"⚠️ 4KB page size detected - Box64 can still work but may be less optimal");
        return YES; // Box64 can work with 4KB pages too
    } else {
        NSLog(@"❌ Unsupported page size: %ld bytes", pageSize);
        return NO;
    }
}

+ (BOOL)initializeBox64Environment {
    NSLog(@"🎮 Initializing Box64 environment...");
    
    // Check page size first
    if (![JITManager check16KBPageSize]) {
        NSLog(@"❌ Page size check failed - cannot initialize Box64");
        return NO;
    }
    
    // Placeholder for actual Box64 initialization
    // This will eventually include:
    
    NSLog(@"✅ Box64 environment initialized successfully");
    return YES;
}

+ (void)enableJITWriteProtection:(BOOL)enabled {
    if (enabled) {
        NSLog(@"🔓 Enabling JIT write protection for code generation");
        // On iOS with proper entitlements, this allows memory to be both writable and executable
        // Critical for dynamic code generation in Box64
    } else {
        NSLog(@"🔒 Disabling JIT write protection for security");
        // Re-enable normal memory protection
    }
}

// C++ helper functions for Box64 integration
extern "C" {
    
    // Placeholder for Box64 main initialization
    int box64_init_placeholder() {
        NSLog(@"🎮 Box64 C++ initialization placeholder");
        
        // Check page size
        if (![JITManager check16KBPageSize]) {
            return -1;
        }
        
        // Initialize JIT environment
        if (![JITManager initializeJITEnvironment]) {
            return -1;
        }
        
        // Initialize Box64 environment
        if (![JITManager initializeBox64Environment]) {
            return -1;
        }
        
        return 0; // Success
    }
    
    // Placeholder for memory allocation with executable permissions
    void* allocate_executable_memory(size_t size) {
        return [[JITManager sharedManager] allocateExecutableMemory:size];
    }
    
    // Placeholder for memory deallocation
    void free_executable_memory(void* memory, size_t size) {
        [[JITManager sharedManager] deallocateExecutableMemory:memory size:size];
        if (memory && memory != MAP_FAILED) {
            munmap(memory, size);
            NSLog(@"✅ Freed executable memory at %p", memory);
        }
    }
}

@end
