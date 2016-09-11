//
//  CWBlogPostView.m
//  Criollo Web
//
//  Created by Cătălin Stan on 09/04/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogPostDetailsViewController.h"
#import "CWBlogPost.h"
#import "CWBlogAuthor.h"
#import "CWBlog.h"
#import "CWAPIController.h"
#import "CWUser.h"

@interface CWBlogPostDetailsViewController ()

@property (nonatomic, readonly, assign) BOOL isNewPost;

@end

@implementation CWBlogPostDetailsViewController

- (BOOL)isNewPost {
    return self.post == nil;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil prefix:(NSString * _Nullable)prefix {
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

    self.vars[@"id"] = self.isNewPost ? @"": self.post.uid;
    self.vars[@"title"] = self.post.title ? : @"";
    self.vars[@"permalink"] = [self.post permalinkForRequest:request];

    if (self.post.publishedDate) {
        self.vars[@"publishedDate"] = [NSString stringWithFormat:@", %@ at %@", [CWBlog formattedDate:self.post.publishedDate], [CWBlog formattedTime:self.post.publishedDate]];
    } else {
        self.vars[@"publishedDate"] = @"";
    }
    self.vars[@"content"] = self.post.renderedContent ? : @"";
    self.vars[@"editable"] = self.isNewPost ? @" contenteditable=\"true\"" : @"";

    self.vars[@"author"] = self.post.author.displayName ? : @"";
    self.vars[@"author-url"] = [self.post.author permalinkForRequest:request];
    self.vars[@"author-image-url"] = self.post.author.imageURL ? : @"";
    self.vars[@"author-location"] = self.post.author.location ? : @"";
    self.vars[@"author-bio"] = self.post.author.bio ? [CWBlog stringByReplacingTwitterTokens:self.post.author.bio] : @"";
    self.vars[@"author-twitter-url"] = self.post.author.twitter ? [NSString stringWithFormat:@"http://twitter.com/%@", self.post.author.twitter] : @"";
    self.vars[@"author-twitter"] = self.post.author.twitter ? : @"";

    NSMutableString* toolbar = [NSMutableString new];
    CWUser * currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
    if ( currentUser ) {
        [toolbar appendString:@"&nbsp;&nbsp;&middot;&nbsp;&nbsp;"];
        [toolbar appendFormat:@"<a href=\"%@/edit\">edit</a>", [self.post permalinkForRequest:request]];
        [toolbar appendFormat:@"&nbsp;&nbsp;<a href=\"%@%@\">new post</a>", CWBlogPath, CWBlogNewPostPath];
    }
    self.vars[@"toolbar"] = toolbar;

    NSMutableArray* tags = [NSMutableArray array];
    for ( CWBlogTag* tag in self.post.tags ) {
        NSString * tagHref = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", [tag permalinkForRequest:request], tag.name];
        [tags addObject:tagHref];
    }
    self.vars[@"tags"] = [tags componentsJoinedByString:@", "];
    self.vars[@"tags-style"] = tags.count == 0 ? @"display: none" : @"";

    // Get the related posts
    NSArray<CWBlogPost *> *relatedPosts = [CWBlog relatedPostsForPost:self.post includeBlanks:NO];
    NSMutableString* related = [NSMutableString string];
    [relatedPosts enumerateObjectsUsingBlock:^(CWBlogPost * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [related appendFormat:@"<li><a href=\"%@\">%@</a></li>", [obj permalinkForRequest:request], obj.title];
        if ( idx > 5 ) {
            *stop = YES;
        }
    }];
    self.vars[@"related"] = related;
    self.vars[@"related-style"] = relatedPosts.count == 0 ? @"display: none" : @"";

    return [super presentViewControllerWithRequest:request response:response];
}

@end
