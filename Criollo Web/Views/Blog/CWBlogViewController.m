//
//  CWBlogViewController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 09/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogViewController.h"
#import "CWAPIController.h"
#import "CWBlogPostViewController.h"
#import "CWBlogPostDetailsViewController.h"
#import "CWBlog.h"
#import "CWBlogAuthor.h"
#import "CWBlogPost.h"
#import "CWBlogTag.h"
#import "CWUser.h"
#import "CWAppDelegate.h"
#import "CWBlogRSSController.h"
#import "CWBlogImageController.h"
#import "CWImageSize.h"
#import "CWBlogImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogViewController ()

@property (nonatomic, strong, readonly) NSMutableString* contents;
@property (nonatomic, strong) NSPredicate* fetchPredicate;
@property (nonatomic, strong) NSString * title;
@property (nonatomic) BOOL showPageTitle;
@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) NSString * ogType;
@property (nonatomic, strong) NSString * metaDescription;
@property (nonatomic, strong) NSString * image;

- (void)setupRoutes;

@end

NS_ASSUME_NONNULL_END

@implementation CWBlogViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil prefix:(NSString *)prefix {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil prefix:prefix];
    if ( self != nil ) {
        _contents = [[NSMutableString alloc] init];
        _title = @"Blog";
        [self setupRoutes];
    }
    return self;
}

#pragma mark - Routing

- (void)setupRoutes {

    __weak CWBlogViewController *controller = self;
    __block CWUser *currentUser;
    
    // Fetches the current user
    CRRouteBlock fetchUserBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
        completionHandler();
    }};
    
    // Checks if a user is logged in and redirects to the login page
    CRRouteBlock authCheckBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        if (currentUser) {
            completionHandler();
            return;
        }
        
        NSString* redirectLocation = [NSString stringWithFormat:@"%@?redirect=%@", CWLoginPath, [request.URL.absoluteURL.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        [response redirectToLocation:redirectLocation];
        return;
    }};

    // Generates the fetchPredicate used for the post archive
    CRRouteBlock archiveBlock =  ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        // Get the month and year from the path
        NSUInteger year = (request.query[@"year"] ? : request.query[@"0"]).integerValue;
        NSUInteger month = (request.query[@"month"] ? : request.query[@"1"]).integerValue;
        
        CWBlogArchivePeriod period = [CWBlog parseYear:year month:month];
        if ( period.year == 0 ) {
            completionHandler();
            return;
        }
        
        // Build a predicate
        CWBlogDatePair *datePair = [CWBlog datePairArchivePeriod:period];
        controller.fetchPredicate = [NSPredicate predicateWithFormat:@"((published = true and publishedDate >= %@ and publishedDate <= %@) or (published = false and lastUpdatedDate >= %@ and lastUpdatedDate <= %@))", datePair.startDate, datePair.endDate, datePair.startDate, datePair.endDate];
        
        // Set the page title
        NSString* humanReadableMonth = @"";
        if ( period.month != 0 ) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MMMM"];
            humanReadableMonth = [NSString stringWithFormat:@" %@ of", [formatter stringFromDate:datePair.startDate]];
        }
        NSString* humanReadableYear = period.year > 0 ? [NSString stringWithFormat:@" %lu", period.year] : @"";
        controller.title = [NSString stringWithFormat:@"Posts published during%@%@", humanReadableMonth, humanReadableYear];
        controller.showPageTitle = YES;
        completionHandler();
    }};

    // Generates the fetchPredicate used for the tag post list
    CRRouteBlock tagBlock =  ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString *handle = request.query[@"tag"];
        controller.fetchPredicate = [NSPredicate predicateWithFormat:@"ANY tags.handle = %@", handle];
        CWBlogTag* tag;
        if ((tag = [CWBlogTag getByHandle:handle])) {
            controller.title = [NSString stringWithFormat:@"Posts tagged ”%@“", tag.name];
            controller.showPageTitle = YES;
        }
        completionHandler();
    }};

    // Generates the fetchPredicate used for the author post list
    CRRouteBlock authorBlock =  ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString *handle = request.query[@"author"];
        controller.fetchPredicate = [NSPredicate predicateWithFormat:@"author.handle = %@", handle];
        CWBlogAuthor *author;
        if ((author = [CWBlogAuthor getByHandle:handle])) {
            controller.title = [NSString stringWithFormat:@"Posts by %@", author.displayName];
            controller.showPageTitle = YES;
        }
        completionHandler();
    }};

    // Displays the "new" post editing form
    CRRouteBlock newPostBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString *renderedPost = [[[CWBlogPostDetailsViewController alloc] initWithNibName:nil bundle:nil post:nil] presentViewControllerWithRequest:request response:response];
        [controller.contents appendString:renderedPost];
        controller.title = @"Create New Blog Post";
        controller.showPageTitle = NO;
        renderedPost = nil;
        completionHandler();
    }};

    // Displays a single blog post in full
    CRRouteBlock singlePostBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSUInteger year = (request.query[@"year"] ? : request.query[@"0"]).integerValue;
        NSUInteger month = (request.query[@"month"] ? : request.query[@"1"]).integerValue;
        NSString *handle = request.query[@"handle"] ? : request.query[@"2"];
        CWBlogPost *post = [CWBlogPost getByHandle:handle year:year month:month];
        if (post != nil) {
            NSString *renderedPost = [[[CWBlogPostDetailsViewController alloc] initWithNibName:nil bundle:nil post:post] presentViewControllerWithRequest:request response:response];
            [controller.contents appendString:renderedPost];
            controller.title = post.title;
            controller.ogType = @"article";
            controller.metaDescription = post.excerpt;
            controller.url = [post permalinkForRequest:request];
            controller.showPageTitle = NO;
            CWImageSizeRepresentation *shareImage;
            if ((shareImage = post.image.sizeRepresentations[CWImageSizeLabelShareImage])) {
                controller.image = [shareImage permalinkForRequest:request];
            }

        }
        completionHandler();
    }};

    // Actually fetches the posts according to the fetchPredicate and displays the list
    CRRouteBlock enumeratePostsBlock =  ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        if (!currentUser) {
            NSString *format = [NSString stringWithFormat:@"%@%@published = true",
                                controller.fetchPredicate.predicateFormat ?: @"",
                                controller.fetchPredicate.predicateFormat ? @" and " : @""];
            controller.fetchPredicate = [NSPredicate predicateWithFormat:format];
        }
        
        RLMResults<CWBlogPost *> *posts;
        if (controller.fetchPredicate) {
            posts = [[CWBlogPost getObjectsWithPredicate:controller.fetchPredicate] sortedResultsUsingKeyPath:@"publishedDate" ascending:NO];
        } else {
            posts = [[CWBlogPost allObjectsInRealm:CWBlog.realm] sortedResultsUsingKeyPath:@"lastUpdatedDate" ascending:NO];
        }
        
        for (CWBlogPost *post in posts) {
            NSString * renderedPost = [[[CWBlogPostViewController alloc] initWithNibName:nil bundle:nil post:post] presentViewControllerWithRequest:request response:response];
            [controller.contents appendString:renderedPost];
        }
        completionHandler();
    }};

    // Checks if there is any content to display and prints out some text
    CRRouteBlock noContentsBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        // Bailout early if there's some contents
        if (controller.contents.length != 0) {
            completionHandler();
            return;
        }

        [controller.contents appendString:@"<div class=\"content\">"];
        
        // Write some message to the user
        [controller.contents appendFormat:@"<p>%@</p>", @"There are no posts to show for now :("];
        
        // Check if there is a user and link to "add post"
        if ([CWUser authenticatedUserForToken:request.cookies[CWUserCookie]]) {
            [controller.contents appendFormat:@"<p><a href=\"%@%@\">Add a new post</a>", CWBlogPath, CWBlogNewPostPath];
        }
        
        [controller.contents appendString:@"</div>"];
        
        completionHandler();
    }};

    // Invokes the controller's presentViewControllerWithRequest:response: method and finishes the response
    CRRouteBlock presentViewControllerBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        NSString * renderedContent = [controller presentViewControllerWithRequest:request response:response];
        [response sendString:renderedContent];
        completionHandler();
    }};
    
    // Feed
    [self add:CWBlogFeedPath controller:[CWBlogRSSController class] recursive:YES method:CRHTTPMethodGet];
    
    // Get the current user
    [self add:fetchUserBlock];

    // New post
    [self get:CWBlogNewPostPath block:authCheckBlock];
    [self get:CWBlogNewPostPath block:newPostBlock];
    [self get:CWBlogNewPostPath block:noContentsBlock];
    [self get:CWBlogNewPostPath block:presentViewControllerBlock];

    // Author
    NSString* authorPath = [CWBlogAuthorPath stringByAppendingPathComponent:@":author"];
    [self get:authorPath block:authorBlock];
    [self get:authorPath block:enumeratePostsBlock];
    [self get:authorPath block:noContentsBlock];
    [self get:authorPath block:presentViewControllerBlock];

    // Tag
    NSString* tagPath = [CWBlogTagPath stringByAppendingPathComponent:@":tag"];
    [self get:tagPath block:tagBlock];
    [self get:tagPath block:enumeratePostsBlock];
    [self get:tagPath block:noContentsBlock];
    [self get:tagPath block:presentViewControllerBlock];

    // Yearly archive
    [self get:CWBlogArchiveYearPath block:archiveBlock];
    [self get:CWBlogArchiveYearPath block:enumeratePostsBlock];
    [self get:CWBlogArchiveYearPath block:noContentsBlock];
    [self get:CWBlogArchiveYearPath block:presentViewControllerBlock];

    // Monthly archive
    [self get:CWBlogArchiveYearMonthPath block:archiveBlock];
    [self get:CWBlogArchiveYearMonthPath block:enumeratePostsBlock];
    [self get:CWBlogArchiveYearMonthPath block:noContentsBlock];
    [self get:CWBlogArchiveYearMonthPath block:presentViewControllerBlock];

    // Single post
    [self get:CWBlogSinglePostPath block:singlePostBlock];
    [self get:CWBlogSinglePostPath block:noContentsBlock];
    [self get:CWBlogSinglePostPath block:presentViewControllerBlock];

    // Edit post
    [self get:CWBlogEditPostPath block:singlePostBlock];
    [self get:CWBlogEditPostPath block:noContentsBlock];
    [self get:CWBlogEditPostPath block:presentViewControllerBlock];

    // Default bblog page
    [self get:CRPathSeparator block:enumeratePostsBlock];
    [self get:CRPathSeparator block:noContentsBlock];
    [self get:CRPathSeparator block:presentViewControllerBlock];
    
    // Images
    [self get:CWBlogSingleImagePath block:CWBlogImageController.sharedController.routeBlock];
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.vars[@"content"] = self.contents.copy;
    if (self.showPageTitle) {
        self.vars[@"content"] = [NSString stringWithFormat:@"<header class=\"page-header content\"><h1 class=\"page-title\">%@</h1></header>%@", self.title, self.vars[@"content"]];
    }
    self.vars[@"title"] = self.title;
    
    if (self.ogType) {
        self.vars[@"og-type"] = self.ogType;
    }
    if (self.url) {
        self.vars[@"url"] = self.url;
    }
    if (self.metaDescription) {
        self.vars[@"meta-description"] = self.metaDescription;
    }

    if (self.image) {
        self.vars[@"image"] = self.image;
    }
    
    self.vars[@"sidebar"] = @"";


    return [super presentViewControllerWithRequest:request response:response];
}

@end
