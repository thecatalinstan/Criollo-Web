//
//  CWBlogPostView.m
//  Criollo Web
//
//  Created by Cătălin Stan on 09/04/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import <CSOddFormatters/CSOddFormatters.h>

#import "CWBlogPostDetailsViewController.h"
#import "CWBlogPost.h"
#import "CWBlogAuthor.h"
#import "CWAPIBlogPost.h"
#import "CWAPIBlogAuthor.h"
#import "CWBlog.h"
#import "CWAppDelegate.h"

@interface CWBlogPostDetailsViewController ()

@property (nonatomic, readonly, assign) BOOL isNewPost;

@end

@implementation CWBlogPostDetailsViewController

- (BOOL)isNewPost {
    return self.post == nil || self.post.objectID.isTemporaryID;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil prefix:(NSString * _Nullable)prefix {
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

    __block CWAPIBlogPost* post;
    __block BOOL isNewPost;
    [[CWAppDelegate sharedBlog].managedObjectContext performBlockAndWait:^{
        post = self.post.APIBlogPost;
        isNewPost = self.isNewPost;
    }];

    self.vars[@"id"] = isNewPost ? @"": post.uid;
    self.vars[@"title"] = post.title ? : @"";
    self.vars[@"permalink"] = [NSString stringWithFormat:@"%@://%@%@%@", request.URL.scheme, request.URL.host, request.URL.port.integerValue == 80 ? @"" : [NSString stringWithFormat:@":%@", request.URL.port], post.publicPath] ? : @"";
    self.vars[@"author"] = post.author.displayName ? : @"";
    if (post.date) {
        self.vars[@"date"] = [NSString stringWithFormat:@", %@ at %@.", [CWBlog formattedDate:post.date], [CWBlog formattedTime:post.date]];
    } else {
        self.vars[@"date"] = @"";
    }
    self.vars[@"content"] = post.renderedContent? : @"";
    self.vars[@"editable"] = isNewPost ? @" contenteditable=\"true\"" : @"";

    return [super presentViewControllerWithRequest:request response:response];
}

@end
