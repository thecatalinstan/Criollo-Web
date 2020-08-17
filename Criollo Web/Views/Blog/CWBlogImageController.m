//
//  CWBlogImageController.m
//  Criollo Web
//
//  Created by Catalin Stan on 17/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import "CWBlogImageController.h"
#import "CWAppDelegate.h"
#import "CWBlogImage.h"
#import "CWImageSize.h"

@interface CRStaticFileManager : NSObject

@property (nonatomic, readonly, copy) CRRouteBlock routeBlock;

+ (instancetype)managerWithFileAtPath:(NSString *)path options:(CRStaticFileServingOptions)options;

@end

@interface CWBlogImageController ()

@property (nonatomic, strong, readonly) NSURL *baseDirectory;

@end

@implementation CWBlogImageController

+ (CWBlogImageController *)sharedController {
    static CWBlogImageController *sharedController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [CWBlogImageController new];
    });
    return sharedController;
}

- (instancetype)init {
    return [self initWithBaseDirectory:CWAppDelegate.baseDirectory];
}

- (instancetype)initWithBaseDirectory:(NSURL *)baseDirectory {
    self = [super init];
    if (self != nil) {
        _baseDirectory = [baseDirectory URLByAppendingPathComponent:@"Images"];
        [self setupDirectory:_baseDirectory];
        
        CWBlogImageController * __weak controller = self;
        _routeBlock = ^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {
            NSString *imagePath = [controller pathForRequestedPath:request.query[@"0"]];
            CRStaticFileManager *manager = [CRStaticFileManager managerWithFileAtPath:imagePath options:CRStaticFileServingOptionsCache];
            manager.routeBlock(request, response, completionHandler);
        };
    }
    return self;
}

- (NSString *)pathForRequestedPath:(NSString *)requestedPath {
    NSURL *directory = [self.baseDirectory URLByAppendingPathComponent:[requestedPath substringToIndex:1].uppercaseString];
    return [directory.path stringByAppendingPathComponent:requestedPath];
}

- (void)setupDirectory:(NSURL *)directory {
    NSString *path = directory.path;
    
    BOOL isDir;
    if ([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir]) {
        if (isDir) {
            return;
        }
        
        [CRApp logErrorFormat:@"%@ Failed to set up the blog's images directory %@. %@", [NSDate date], path, @"Expected a folder to store the blog's images, found a file."];
        return;
    }
        
    NSError* error;
    if (![NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
        [CRApp logErrorFormat:@"%@ Failed to set up the blog's images directory %@. %@", [NSDate date], path, error.localizedDescription];
        return;
    }
    
    [CRApp logFormat:@"%@ Successfully set up the blog's images directory %@.", [NSDate date], path];
}

- (BOOL)preocessUploadedFile:(CRUploadedFile *)file image:(CWBlogImage *)image error:(NSError *__autoreleasing  _Nullable *)error {
    // Move the main image
    NSString *imagePath = [self pathForRequestedPath:image.publicPath.lastPathComponent];
    [self setupDirectory:[NSURL fileURLWithPath:imagePath.stringByDeletingLastPathComponent]];
    
    if (![NSFileManager.defaultManager moveItemAtPath:file.temporaryFileURL.path toPath:imagePath error:error]) {
        return NO;
    }
    
    // Iterate through the size representations and generate the appropriate files
    for (CWImageSizeRepresentation *rep in image.sizeRepresentations) {
        if (![self gnerateImageSizeRepresentation:rep forImageAtPath:imagePath error:error]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)gnerateImageSizeRepresentation:(CWImageSizeRepresentation *)representation forImageAtPath:(NSString *)imagePath error:(NSError *__autoreleasing  _Nullable *)error  {
    NSString *repPath = [self pathForRequestedPath:representation.publicPath.lastPathComponent];
    if (![NSFileManager.defaultManager copyItemAtPath:imagePath toPath:repPath error:error]) {
        return NO;
    }
    return YES;
}

@end
