//
//  CWAPIBlogImage.m
//  Criollo Web
//
//  Created by Cătălin Stan on 11/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import "CWAPIBlogImage.h"
#import "CWBlog.h"
#import "CWBlogImage.h"
#import "CWImageSize.h"

@implementation CWAPIBlogImage

#pragma mark - CWSchemaProxy

- (CWSchema *)schemaObject {
    RLMRealm * realm = [CWBlog realm];
    CWBlogImage* image;
    if (self.uid) {
        image = [CWBlogImage objectInRealm:realm forPrimaryKey:self.uid];
    }
    if (image == nil) {
        image = [[CWBlogImage alloc] init];
    }
    image.filename = self.filename;
    image.mimeType = self.mimeType;
    image.filesize = self.filesize;
    image.handle = self.handle;
    return image;
}

@end
