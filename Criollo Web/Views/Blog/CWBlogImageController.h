//
//  CWBlogImageController.h
//  Criollo Web
//
//  Created by Catalin Stan on 17/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

@class CWBlogImage, CWImageSizeRepresentation;

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogImageController : NSObject

@property (nonatomic, copy) CRRouteBlock routeBlock;

@property (nonatomic, strong, readonly, class) CWBlogImageController *sharedController;

- (instancetype)initWithBaseDirectory:(NSURL *)baseDirectory NS_DESIGNATED_INITIALIZER;

- (NSString *)pathForRequestedPath:(NSString *)requestedPath;

- (BOOL)preocessUploadedFile:(CRUploadedFile *)file
                  publicPath:(NSString *)publicPath
    imageSizeRepresentations:(NSArray<CWImageSizeRepresentation *> *)representations
                       error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
