//
//  CWBlogTag.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogTag.h"
#import "CWBlog.h"
#import "CWAPIBlogTag.h"

@implementation CWBlogTag

#pragma mark - Realm

+ (NSArray<NSString *> *)indexedProperties {
    static NSMutableArray<NSString *> *indexedProperties;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        indexedProperties = [NSMutableArray arrayWithArray:[[self superclass] indexedProperties]];
        [indexedProperties addObjectsFromArray:@[@"name"]];
    });
    return indexedProperties;
}

#pragma mark - API

- (NSString *)publicPath {
    return [NSString stringWithFormat:@"%@%@/%@", CWBlogPath, CWBlogTagPath, self.handle];
}

#pragma mark - CWModelProxy

- (CWModel *)modelObject {
    CWAPIBlogTag* tag = [[CWAPIBlogTag alloc] init];
    tag.uid = self.uid;
    tag.publicPath = self.publicPath;
    tag.name = self.name;
    tag.handle = self.handle;
    return tag;
}

@end
