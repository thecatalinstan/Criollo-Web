//
//  CWBlogAuthor.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogAuthor.h"
#import "CWBlog.h"
#import "CWAPIBlogAuthor.h"

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

#pragma mark - ModelProxy

- (CWModel *)modelObject {
    CWAPIBlogAuthor *author = [[CWAPIBlogAuthor alloc] init];
    author.uid = self.uid;
    author.publicPath = self.publicPath;
    author.displayName = self.displayName;
    author.email = self.email;
    author.user = self.user;
    author.handle = self.handle;
    author.twitter = self.twitter;
    author.imageURL = self.imageURL;
    author.bio = self.bio;
    return author;
}

# pragma mark - Fetching

+ (instancetype)getByUser:(NSString *)username {
    return [[self class] getSingleObjectWhere:@"user = %@", username];
}

@end
