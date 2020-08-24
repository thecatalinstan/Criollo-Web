//
//  CWBlogPostView.m
//  Criollo Web
//
//  Created by Cătălin Stan on 09/04/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogPostViewController.h"
#import "CWBlogPost.h"
#import "CWBlogAuthor.h"
#import "CWBlog.h"
#import "CWUser.h"
#import "CWAPIController.h"
#import "CWBlogImage.h"
#import "CWImageSize.h"

@implementation CWBlogPostViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil prefix:(NSString *)prefix {
    return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil post:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil post:(CWBlogPost *)post {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil prefix:nil];
    if (self != nil) {
        _post = post;
    }
    return self;
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.vars[@"id"] = self.post.uid;
    self.vars[@"title"] = self.post.title ?: @"";
    if (!self.post.published) {
        self.vars[@"title"] = [self.vars[@"title"] stringByAppendingString:@" [draft]"];
    }
    self.vars[@"permalink"] = [self.post permalinkForRequest:request];
    self.vars[@"author"] = self.post.author.displayName ?: @"";
    self.vars[@"author-url"] = [self.post.author permalinkForRequest:request];
    
    NSDate *date = self.post.publishedDate ?: self.post.lastUpdatedDate;
    self.vars[@"publishedDate"] = [NSString stringWithFormat:@", %@ at %@", [CWBlog formattedDate:date], [CWBlog formattedTime:date]];

    self.vars[@"content"] = self.post.excerpt ?: ( self.post.renderedContent ?: @"" );

    NSMutableString *toolbar = [[NSMutableString alloc] initWithCapacity:255];
    if ([CWUser authenticatedUserForToken:request.cookies[CWUserCookie]]) {
        [toolbar appendString:@"&nbsp;&nbsp;&middot;&nbsp;&nbsp;"];
        [toolbar appendFormat:@"<a href=\"%@/edit\">edit</a>", [self.post permalinkForRequest:request]];
        [toolbar appendFormat:@"&nbsp;&nbsp;<a href=\"%@%@\">new post</a>", CWBlogPath, CWBlogNewPostPath];
    }
    self.vars[@"toolbar"] = toolbar;
    
    CWImageSizeRepresentation *largeImage;
    if ((largeImage = self.post.image.sizeRepresentations[CWImageSizeLabelThumb])) {
        self.vars[@"article-thumbnail-class"] = @"";
        self.vars[@"article-excerpt-class"] = @"";
    } else {
        self.vars[@"article-thumbnail-class"] = @"hidden";
        self.vars[@"article-excerpt-class"] = @"no-thumb";
    }
    self.vars[@"article-thumbnail-url"] = [largeImage permalinkForRequest:request];

    return [super presentViewControllerWithRequest:request response:response];
}

@end
