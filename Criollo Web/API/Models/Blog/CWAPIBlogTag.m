//
//  CWAPIBlogTag.m
//  Criollo Web
//
//  Created by Cătălin Stan on 16/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWAPIBlogTag.h"
#import "CWBlog.h"
#import "CWBlogTag.h"

@implementation CWAPIBlogTag

#pragma mark - CWSchemaProxy

- (CWSchema *)schemaObject {
    RLMRealm * realm = [CWBlog realm];
    CWBlogTag* tag = [CWBlogTag objectInRealm:realm forPrimaryKey:self.uid];
    if ( tag == nil ) {
        tag = [[CWBlogTag alloc] init];
    }
    tag.name = self.name;
    tag.handle = self.handle;
    return tag;
}

@end
