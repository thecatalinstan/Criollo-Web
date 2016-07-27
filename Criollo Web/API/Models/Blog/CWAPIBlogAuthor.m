//
//  CWAPIBlogAuthor.m
//  Criollo Web
//
//  Created by Cătălin Stan on 16/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Realm/Realm.h>

#import "CWAPIBlogAuthor.h"
#import "CWAppDelegate.h"
#import "CWBlog.h"
#import "CWBlogAuthor.h"

@implementation CWAPIBlogAuthor

#pragma mark - CWSchemaProxy

- (CWSchema *)schemaObject {
    RLMRealm * realm = [CWAppDelegate sharedBlog].realm;
    CWBlogAuthor* author = [CWBlogAuthor objectInRealm:realm forPrimaryKey:self.uid];
    if ( author == nil ) {
        author = [[CWBlogAuthor alloc] init];
    }
    author.user = self.user;
    author.displayName = self.displayName;
    author.email = self.email;
    author.handle = self.handle;
    return author;
}

@end

