//
//  CWBlogPostView.m
//  Criollo Web
//
//  Created by Cătălin Stan on 09/04/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <CSOddFormatters/CSOddFormatters.h>

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
    self.vars[@"permalink"] = [NSString stringWithFormat:@"%@://%@%@%@", request.URL.scheme, request.URL.host, request.URL.port.integerValue == 80 ? @"" : [NSString stringWithFormat:@":%@", request.URL.port], self.post.publicPath] ? : @"";
    self.vars[@"author"] = self.post.author.displayName ? : @"";
    if (self.post.date) {
        self.vars[@"date"] = [NSString stringWithFormat:@", %@ at %@.", [CWBlog formattedDate:self.post.date], [CWBlog formattedTime:self.post.date]];
    } else {
        self.vars[@"date"] = @"";
    }
    self.vars[@"content"] = self.post.renderedContent ? : @"";
    
    return [super presentViewControllerWithRequest:request response:response];
}

@end
