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
    post.date = self.date;
    post.handle = self.handle;
    post.title = self.title;
    post.content = self.content;
    post.renderedContent = self.renderedContent;
    post.author = (CWBlogAuthor *)self.author.schemaObject;

    if ( self.tags ) {
        if ( !post.tags ) {
            post.tags = (RLMArray<CWBlogTag *><CWBlogTag> *) [[RLMArray alloc] initWithObjectClassName:@"CWBlogTag"];
        }
        [self.tags enumerateObjectsUsingBlock:^(CWAPIBlogTag * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [post.tags addObject:(CWBlogTag *)obj.schemaObject];
        }];
    } else {
        self.tags = nil;
    }

    return post;
}

@end
