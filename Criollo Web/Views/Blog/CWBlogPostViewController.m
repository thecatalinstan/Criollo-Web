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

@implementation CWBlogPostViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil prefix:(NSString *)prefix {
    return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil post:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil post:(CWBlogPost *)post {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil prefix:nil];
    if ( self != nil ) {
        self.post = post;
    }
    return self;
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.vars[@"id"] = self.post.uid;
    self.vars[@"title"] = self.post.title ? : @"";
    self.vars[@"permalink"] = [self.post permalinkForRequest:request];
    self.vars[@"author"] = self.post.author.displayName ? : @"";
    self.vars[@"author-url"] = [self.post.author permalinkForRequest:request];
    if (self.post.date) {
        self.vars[@"date"] = [NSString stringWithFormat:@", %@ at %@.", [CWBlog formattedDate:self.post.date], [CWBlog formattedTime:self.post.date]];
    } else {
        self.vars[@"date"] = @"";
    }
    self.vars[@"content"] = self.post.renderedContent ? : @"";

    return [super presentViewControllerWithRequest:request response:response];
}

@end
