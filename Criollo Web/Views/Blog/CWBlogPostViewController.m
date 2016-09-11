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

@implementation CWBlogPostViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil prefix:(NSString *)prefix {
    return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil post:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil post:(CWBlogPost *)post {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil prefix:nil];
    if ( self != nil ) {
        _post = post;
    }
    return self;
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.vars[@"id"] = self.post.uid;
    self.vars[@"title"] = self.post.title ? : @"";
    self.vars[@"permalink"] = [self.post permalinkForRequest:request];
    self.vars[@"author"] = self.post.author.displayName ? : @"";
    self.vars[@"author-url"] = [self.post.author permalinkForRequest:request];
    if (self.post.publishedDate) {
        self.vars[@"publishedDate"] = [NSString stringWithFormat:@", %@ at %@", [CWBlog formattedDate:self.post.publishedDate], [CWBlog formattedTime:self.post.publishedDate]];
    } else {
        self.vars[@"publishedDate"] = @"";
    }
    self.vars[@"content"] = self.post.excerpt ? : ( self.post.renderedContent ? : @"" );

    NSMutableString* toolbar = [NSMutableString new];
    CWUser * currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
    if ( currentUser ) {
        [toolbar appendString:@"&nbsp;&nbsp;&middot;&nbsp;&nbsp;"];
        [toolbar appendFormat:@"<a href=\"%@/edit\">edit</a>", [self.post permalinkForRequest:request]];
        [toolbar appendFormat:@"&nbsp;&nbsp;<a href=\"%@%@\">new post</a>", CWBlogPath, CWBlogNewPostPath];
    }
    self.vars[@"toolbar"] = toolbar;

    return [super presentViewControllerWithRequest:request response:response];
}

@end
