//
//  CWBlogPostView.m
//  Criollo Web
//
//  Created by Cătălin Stan on 09/04/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import <CSOddFormatters/CSOddFormatters.h>

#import "CWBlogPostViewController.h"
#import "CWBlogPost.h"
#import "CWBlogAuthor.h"
#import "CWAPIBlogPost.h"
#import "CWAPIBlogAuthor.h"
#import "CWBlog.h"
#import "CWAppDelegate.h"

@implementation CWBlogPostViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil post:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil post:(CWBlogPost *)post {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self != nil ) {
        self.post = post;
    }
    return self;
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    __block CWAPIBlogPost* post;
    __block NSString* path;
    [[CWAppDelegate sharedBlog].managedObjectContext performBlockAndWait:^{
        post = self.post.APIBlogPost;
        path = self.post.path;
    }];

    self.templateVariables[@"id"] = post.uid;
    self.templateVariables[@"title"] = post.title ? : @"";
    self.templateVariables[@"permalink"] = [NSString stringWithFormat:@"%@://%@%@%@", request.URL.scheme, request.URL.host, request.URL.port.integerValue == 80 ? @"" : [NSString stringWithFormat:@":%@", request.URL.port] ,path] ? : @"";
    self.templateVariables[@"author"] = post.author.displayName ? : @"";
    if (post.date) {
        self.templateVariables[@"date"] = [NSString stringWithFormat:@", %@ at %@.", [CWBlog formattedDate:post.date], [CWBlog formattedTime:post.date]];
    } else {
        self.templateVariables[@"date"] = @"";
    }
    self.templateVariables[@"content"] = post.renderedContent? : @"";
    
    return [super presentViewControllerWithRequest:request response:response];
}

@end
