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
    return [NSString stringWithFormat:@"%@%@/%@", CWBlogPath, CWBlogImagePath, self.handle];
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
    return image;
}
@end
