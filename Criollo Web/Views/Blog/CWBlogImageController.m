//
//  CWBlogImageController.m
//  Criollo Web
//
//  Created by Catalin Stan on 17/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import "CWBlogImageController.h"
#import "CWAppDelegate.h"



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
//            [response sendFormat:@"%s %@", __PRETTY_FUNCTION__, imagePath];
            
            CRStaticFileManager *manager = [CRStaticFileManager managerWithFileAtPath:imagePath options:CRStaticFileServingOptionsCache];
            manager.routeBlock(request, response, completionHandler);
        };
    }
    return self;
}

- (NSString *)pathForRequestedPath:(NSString *)requestedPath {
    NSURL *directory = [self.baseDirectory URLByAppendingPathComponent:[requestedPath substringToIndex:1]];
    return [directory.path stringByAppendingPathComponent:requestedPath];
}

- (void)setupDirectory:(NSURL *)directory {
    NSError* error;
    BOOL shouldFail = NO;
    NSString* failureReason = @"There was an error creating or loading the blog's images directory.";

    NSDictionary *properties = [directory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties) {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            failureReason = @"Expected a folder to store the blog's images, found a file.";
            shouldFail = YES;
        }
    } else if (error.code == NSFileReadNoSuchFileError) {
        error = nil;
        [NSFileManager.defaultManager createDirectoryAtPath:self.baseDirectory.path withIntermediateDirectories:YES attributes:nil error:&error];
    }

    if (shouldFail || error) {
        if (error) {
            failureReason = error.localizedDescription;
        }
        [CRApp logErrorFormat:@"%@ Failed to set up the blog's images directory %@. %@", [NSDate date], directory, failureReason];
        [CRApp terminate:nil];
    } else {
        [CRApp logFormat:@"%@ Successfully set up the blog's images directory %@.", [NSDate date], directory.path];
    }
}

@end
