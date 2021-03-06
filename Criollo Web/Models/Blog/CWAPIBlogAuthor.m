//
//  CWAPIBlogAuthor.m
//  Criollo Web
//
//  Created by Cătălin Stan on 16/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Realm/Realm.h>

#import "CWAPIBlogAuthor.h"
#import "CWBlog.h"
#import "CWBlogAuthor.h"

@implementation CWAPIBlogAuthor

#pragma mark - CWSchemaProxy

- (CWSchema *)schemaObject {
    RLMRealm * realm = [CWBlog realm];
    CWBlogAuthor* author;
    if ( self.uid ) {
        author = [CWBlogAuthor objectInRealm:realm forPrimaryKey:self.uid];
    }
    if ( author == nil ) {
        author = [[CWBlogAuthor alloc] init];
    }
    author.user = self.user;
    author.displayName = self.displayName;
    author.email = self.email;
    author.handle = self.handle;
    author.twitter = self.twitter;
    author.imageURL = self.imageURL;
    author.bio = self.bio;
    author.location = self.location;
    return author;
}

@end

