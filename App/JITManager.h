#ifndef JITManager_h
#define JITManager_h

#import <Foundation/Foundation.h>
#import <sys/ptrace.h>

@interface JITManager : NSObject

// Initialize JIT environment with ptrace debugging signal
+ (BOOL)initializeJITEnvironment;

// Check if 16KB page size is supported
+ (BOOL)check16KBPageSize;

// Placeholder for Box64 initialization
+ (BOOL)initializeBox64Environment;

// Enable/disable JIT write protection
+ (void)enableJITWriteProtection:(BOOL)enabled;

@end

#endif /* JITManager_h */
