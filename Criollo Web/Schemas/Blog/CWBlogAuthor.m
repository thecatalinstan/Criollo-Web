//
//  CWBlogAuthor.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogAuthor.h"
#import "CWBlog.h"

@implementation CWBlogAuthor

#pragma mark - Realm

+ (NSArray<NSString *> *)indexedProperties {
    static NSMutableArray<NSString *> *indexedProperties;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        indexedProperties = [NSMutableArray arrayWithArray:[[self superclass] indexedProperties]];
        [indexedProperties addObjectsFromArray:@[@"user"]];
    });
    return indexedProperties;
}

#pragma mark - API

- (NSString *)publicPath {
    return [NSString stringWithFormat:@"%@%@/%@", CWBlogPath, CWBlogAuthorPath, self.handle];
}

@end
