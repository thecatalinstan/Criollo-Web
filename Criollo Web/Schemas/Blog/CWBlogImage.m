//
//  CWBlogImage.m
//  Criollo Web
//
//  Created by Cătălin Stan on 11/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import "CWBlogImage.h"
#import "CWBlog.h"
#import "CWAPIBlogImage.h"
#import "CWImageSize.h"

@implementation CWBlogImage

#pragma mark - Realm

+ (NSArray<NSString *> *)indexedProperties {
    static NSMutableArray<NSString *> *indexedProperties;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        indexedProperties = [NSMutableArray arrayWithArray:[[self superclass] indexedProperties]];
        [indexedProperties addObjectsFromArray:@[@"size"]];
    });
    return indexedProperties;
}

#pragma mark - API

- (NSString *)publicPath {
    return [self publicPathForImageSize:nil];
}

- (NSString *)publicPathForImageSize:(CWImageSize *)imageSize {
    NSString *baseName;
    if (!(baseName = self.handle)) {
        return nil;
    }
    
    if (imageSize) {
        baseName = [baseName stringByAppendingFormat:@"_%lux%lu", (unsigned long)imageSize.width, (unsigned long)imageSize.height];
    }
    return [NSString stringWithFormat:@"%@%@/%@", CWBlogPath, CWBlogImagePath, [baseName stringByAppendingPathExtension:self.filename.pathExtension]];
}

- (NSArray<CWImageSizeRepresentation *> *)sizeRepresentations {
    if (!self.handle) {
        return nil;
    }
    
    NSArray<CWImageSize *> *sizes = CWImageSize.availableSizes;
    NSMutableArray<CWImageSizeRepresentation *> *sizeRepresentations = [NSMutableArray<CWImageSizeRepresentation *> arrayWithCapacity:sizes.count];
    for (CWImageSize *size in sizes) {
        CWImageSizeRepresentation *sizeRepresentation = [[CWImageSizeRepresentation alloc] init];
        sizeRepresentation.publicPath = [self publicPathForImageSize:size];
        sizeRepresentation.width = size.width;
        sizeRepresentation.height = size.height;
        [sizeRepresentations addObject:sizeRepresentation];
    }
    return sizeRepresentations;
}

#pragma mark - CWModelProxy

- (CWModel *)modelObject {
    CWAPIBlogImage* image = [[CWAPIBlogImage alloc] init];
    image.uid = self.uid;
    image.publicPath = self.publicPath;
    image.filename = self.filename;
    image.mimeType = self.mimeType;
    image.filesize = self.filesize;
    image.handle = self.handle;
    image.sizeRepresentations =  (NSArray<CWImageSizeRepresentation *><CWImageSizeRepresentation,Optional> *)self.sizeRepresentations;
    return image;
}

@end
