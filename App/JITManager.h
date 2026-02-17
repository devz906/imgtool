#ifndef JITManager_h
#define JITManager_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JITManager : NSObject

// Initialize JIT environment for iOS
+ (instancetype)sharedManager;

// Enable JIT using iOS-compatible methods
- (BOOL)enableJITWithError:(NSError *_Nullable *_Nullable)error;

// Check if 16KB page size is supported (A18 Pro)
- (BOOL)supports16KPages;

// Placeholder for Box64 initialization
- (BOOL)initializeBox64With16KPages:(BOOL)use16KPages error:(NSError *_Nullable *_Nullable)error;

// Memory management for JIT
- (void *_Nullable)allocateExecutableMemory:(size_t)size;
- (void)deallocateExecutableMemory:(void *_Nullable)memory size:(size_t)size;

@end

NS_ASSUME_NONNULL_END

#endif /* JITManager_h */
