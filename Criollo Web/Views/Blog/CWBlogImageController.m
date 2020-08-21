//
//  CWBlogImageController.m
//  Criollo Web
//
//  Created by Catalin Stan on 17/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "CWBlogImageController.h"
#import "CWAppDelegate.h"
#import "CWBlogImage.h"
#import "CWImageSize.h"
#import "CWBlog.h"

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
        _routeBlock = ^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) { @autoreleasepool {
            NSString *imagePath = [controller pathForRequestedPath:request.query[@"0"]];
            CRStaticFileManager *manager = [CRStaticFileManager managerWithFileAtPath:imagePath options:CRStaticFileServingOptionsCache];
            manager.routeBlock(request, response, completionHandler);
        }};
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

- (BOOL)preocessUploadedFile:(CRUploadedFile *)file publicPath:(NSString *)publicPath imageSizeRepresentations:(NSArray<CWImageSizeRepresentation *> *)representations error:(NSError *__autoreleasing  _Nullable *)error {
    NSString *path = [self pathForRequestedPath:publicPath.lastPathComponent];
    [self setupDirectory:[NSURL fileURLWithPath:path.stringByDeletingLastPathComponent]];
    
    // Move the main image
    if (![NSFileManager.defaultManager moveItemAtPath:file.temporaryFileURL.path toPath:path error:error]) {
        return NO;
    }
    
    NSData *data;
    if (!(data = [[NSData alloc] initWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:error])) {
        return NO;
    }
    
    NSImage *image;
    if (!(image = [[NSImage alloc] initWithData:data])) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:CWBlogErrorDomain code:CWBlogInvalidImage userInfo:@{
                NSLocalizedDescriptionKey: @"Unable to create image.",
                NSURLErrorFailingURLStringErrorKey: [NSURL fileURLWithPath:path].absoluteString
            }];
        }
        return NO;
    }
    
    // Iterate through the size representations and generate the appropriate files
    for (CWImageSizeRepresentation *rep in representations) {
        if (![self gnerateImageSizeRepresentation:rep forImage:image error:error]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)deleteImageAtPublicPath:(NSString *)publicPath imageSizeRepresentations:(NSArray<CWImageSizeRepresentation *> *)representations error:(NSError *__autoreleasing  _Nullable *)error {
    NSString *mainImagePath = [self pathForRequestedPath:publicPath.lastPathComponent];
    
    NSMutableArray<NSString *> *pathsToDelete = [NSMutableArray arrayWithCapacity:representations.count + 1];
    pathsToDelete[0] = mainImagePath;
    for (CWImageSizeRepresentation *rep in representations) {
        NSString *repImagePath;
        if(!(repImagePath = [self pathForRequestedPath:rep.publicPath.lastPathComponent])) {
            continue;
        }
        [pathsToDelete addObject:repImagePath];
    }
        
    // Delete the main image file and size representations
    for (NSString *path in pathsToDelete) {
        if (![NSFileManager.defaultManager removeItemAtPath:path error:error]) {
            return NO;
        }
    }
       
    // Delete folder if empty
    NSString *imageDir = mainImagePath.stringByDeletingLastPathComponent;
    NSArray<NSString *> *remainingFilesImageDir;
    if (!(remainingFilesImageDir = [NSFileManager.defaultManager contentsOfDirectoryAtPath:imageDir error:error])) {
        return NO;
    }
    
    if (NSNotFound == ([remainingFilesImageDir indexOfObjectPassingTest:^BOOL(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.pathExtension localizedCaseInsensitiveCompare:@"jpg"] == NSOrderedSame;
    }])) {
        return [NSFileManager.defaultManager removeItemAtPath:imageDir error:error];
    }
        
    return YES;
}

- (BOOL)gnerateImageSizeRepresentation:(CWImageSizeRepresentation *)representation forImage:(NSImage *)image error:(NSError *__autoreleasing  _Nullable *)error  {
    // Resample the image
    NSImage *scaledImage;
    if (!(scaledImage = [self scaleImage:image toSize:NSMakeSize(representation.width, representation.height) error:error])) {
        return NO;
    }
    
    // Output to representation path
    CGImageRef scaledImageRef = [scaledImage CGImageForProposedRect:NULL context:nil hints:nil];
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:scaledImageRef];
    rep.size = scaledImage.size;
    
    NSData *data = [rep representationUsingType:NSJPEGFileType properties:@{
        NSImageCompressionFactor: @(0.85),
        NSImageProgressive: @YES,
        NSImageFallbackBackgroundColor: NSColor.whiteColor
    }];
    
    NSString *repPath = [self pathForRequestedPath:representation.publicPath.lastPathComponent];
    if (![data writeToFile:repPath options:NSDataWritingAtomic error:error]) {
        return NO;
    }
    
    return YES;
}

- (NSImage *)scaleImage:(NSImage *)image toSize:(NSSize)targetSize error:(NSError *__autoreleasing *)error {
    NSSize imageSize = image.size;
    CGFloat width  = imageSize.width;
    CGFloat height = imageSize.height;
    
    if (width == 0 || height == 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:CWBlogErrorDomain code:CWBlogInvalidImage userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"The image size is ivalid. %@", NSStringFromSize(imageSize)]
            }];
        }
        return nil;
    }
    
    CGFloat targetWidth  = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat widthFactor  = targetSize.width / width;
    CGFloat heightFactor = targetSize.height / height;
    
    CGFloat scaleFactor  = MAX(widthFactor, heightFactor);
    
    NSSize scaledSize = NSZeroSize;
    scaledSize.width = imageSize.width * scaleFactor;
    scaledSize.height = imageSize.height * scaleFactor;
    
    NSPoint thumbnailPoint = NSZeroPoint;
    if (widthFactor > heightFactor) {
        thumbnailPoint.y = (targetHeight - scaledSize.height) * 0.5;
    } else if (widthFactor < heightFactor) {
        thumbnailPoint.x = (targetWidth - scaledSize.width) * 0.5;
    }
    
    NSRect thumbnailRect;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size = scaledSize;
    
    NSImage *result = [[NSImage alloc] initWithSize:targetSize];
    [result lockFocus];
    [image drawInRect:thumbnailRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [result unlockFocus];
    
    return result;
}

@end
