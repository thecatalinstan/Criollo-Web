//
//  CWAPIBlogPost.m
//  Criollo Web
//
//  Created by Cătălin Stan on 15/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWAPIBlogPost.h"
#import "CWBlog.h"
#import "CWBlogPost.h"
#import "CWBlogAuthor.h"
#import "CWBlogTag.h"
#import "CWAPIBlogTag.h"
#import "CWAPIBlogAuthor.h"

@implementation CWAPIBlogPost

#pragma mark - CWSchemaProxy

- (CWSchema *)schemaObject {
    RLMRealm * realm = [CWBlog realm];
    CWBlogPost* post;
    if ( self.uid ) {
        post = [CWBlogPost objectInRealm:realm forPrimaryKey:self.uid];
    }
    if ( post == nil ) {
        post = [[CWBlogPost alloc] init];
    }
    post.publishedDate = self.publishedDate;
    post.handle = self.handle;
    post.title = self.title;
    post.content = self.content;
    post.renderedContent = self.renderedContent;
    post.excerpt = self.excerpt;
    post.author = (CWBlogAuthor *)self.author.schemaObject;
    post.published = self.published;

    [post.tags removeAllObjects];
    if ( self.tags ) {
        [self.tags enumerateObjectsUsingBlock:^(CWAPIBlogTag * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [post.tags addObject:(CWBlogTag *)obj.schemaObject];
        }];
    }

    return post;
}

@end
