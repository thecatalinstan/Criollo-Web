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

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogViewController ()

@property (nonatomic, strong, readonly) NSMutableString* contents;
@property (nonatomic, strong) NSPredicate* fetchPredicate;
@property (nonatomic, strong) NSString * title;
@property (nonatomic) BOOL showPageTitle;
@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) NSString * ogType;
@property (nonatomic, strong) NSString * metaDescription;

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
        _fetchPredicate = [NSPredicate predicateWithFormat:@"published = true"];
    }
    return self;
}

#pragma mark - Routing

- (void)setupRoutes {
    CWBlogViewController* __weak controller = self;

    // Checks if a user is logged in and redirects to the login page
    CRRouteBlock authCheckBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CWUser* currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
        if ( !currentUser ) {
            NSString* redirectLocation = [NSString stringWithFormat:@"%@?redirect=%@", CWLoginPath, [request.URL.absoluteURL.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            [response redirectToLocation:redirectLocation];
            return;
        }
        completionHandler();
    };

    // Generates the fetchPredicate used for the post archive
    CRRouteBlock archiveBlock =  ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
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
        controller.fetchPredicate = [NSPredicate predicateWithFormat:@"publishedDate >= %@ and publishedDate <= %@ and published = true", datePair.startDate, datePair.endDate];

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
    };

    // Generates the fetchPredicate used for the tag post list
    CRRouteBlock tagBlock =  ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* handle = request.query[@"tag"];
        controller.fetchPredicate = [NSPredicate predicateWithFormat:@"ANY tags.handle = %@ and published = true", handle];
        CWBlogTag* tag = [CWBlogTag getByHandle:handle];
        if ( tag ) {
            controller.title = [NSString stringWithFormat:@"Posts tagged ”%@“", tag.name];
            controller.showPageTitle = YES;
        }
        completionHandler();
    };

    // Generates the fetchPredicate used for the author post list
    CRRouteBlock authorBlock =  ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* handle = request.query[@"author"];
        controller.fetchPredicate = [NSPredicate predicateWithFormat:@"author.handle = %@ and published = true", handle];
        CWBlogAuthor* author = [CWBlogAuthor getByHandle:handle];
        if ( author ) {
            controller.title = [NSString stringWithFormat:@"Posts by %@", author.displayName];
            controller.showPageTitle = YES;
        }
        completionHandler();
    };

    // Displays the "new" post editing form
    CRRouteBlock newPostBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [controller.contents appendString:[[[CWBlogPostDetailsViewController alloc] initWithNibName:nil bundle:nil post:nil] presentViewControllerWithRequest:request response:response]];
        controller.title = @"Create New Blog Post";
        controller.showPageTitle = NO;
        completionHandler();
    };

    // Displays a single blog post in full
    CRRouteBlock singlePostBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSUInteger year = (request.query[@"year"] ? : request.query[@"0"]).integerValue;
        NSUInteger month = (request.query[@"month"] ? : request.query[@"1"]).integerValue;
        NSString* handle = request.query[@"handle"] ? : request.query[@"2"];
        CWBlogPost* post = [CWBlogPost getByHandle:handle year:year month:month];
        if (post != nil) {
            [controller.contents appendString:[[[CWBlogPostDetailsViewController alloc] initWithNibName:nil bundle:nil post:post] presentViewControllerWithRequest:request response:response]];
            controller.title = post.title;
            controller.ogType = @"article";
            controller.metaDescription = post.excerpt;
            controller.url = [post permalinkForRequest:request];
            controller.showPageTitle = NO;
        }
        completionHandler();
    };

    // Actually fetches the posts according to the fetchPredicate and displays the list
    CRRouteBlock enumeratePostsBlock =  ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        RLMResults* posts = [[CWBlogPost getObjectsWithPredicate:self.fetchPredicate] sortedResultsUsingProperty:@"publishedDate" ascending:NO];
        for ( CWBlogPost *post in posts ) {
            CWBlogPostViewController* postViewController = [[CWBlogPostViewController alloc] initWithNibName:nil bundle:nil post:post];
            [controller.contents appendString:[postViewController presentViewControllerWithRequest:request response:response]];
        }
        completionHandler();
    };

    // Checks if there is any content to display and prints out some text
    CRRouteBlock noContentsBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

        // Bailout early if there's some contents
        if ( controller.contents.length != 0 ) {
            completionHandler();
            return;
        }
        [controller.contents appendFormat:@"<p>%@</p>", @"There are no posts to show for now :("];

        // Check if there is a user and link to "add post"
        CWUser* currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
        if ( !currentUser ) {
            completionHandler();
            return;
        }

        [controller.contents appendFormat:@"<p><a href=\"%@%@\">Add a new post</a>", CWBlogPath, CWBlogNewPostPath];
        completionHandler();
    };

    // Invokes the controller's presentViewControllerWithRequest:response: method and finishes the response
    CRRouteBlock presentViewControllerBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response sendString:[controller presentViewControllerWithRequest:request response:response]];
        completionHandler();
    };

    // Add the routes

    // Feed
    [self add:CWBlogFeedPath controller:[CWBlogRSSController class] recursive:YES method:CRHTTPMethodGet];

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
    [self get:@"/" block:enumeratePostsBlock];
    [self get:@"/" block:noContentsBlock];
    [self get:@"/" block:presentViewControllerBlock];
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.vars[@"content"] = self.contents;
    if (self.showPageTitle) {
        self.vars[@"content"] = [NSString stringWithFormat:@"<header class=\"page-header\"><h1 class=\"page-title\">%@</h1></header>%@", self.title, self.vars[@"content"]];
    }
    self.vars[@"title"] = self.title;
    if ( self.ogType ) {
        self.vars[@"og-type"] = self.ogType;
    }
    if ( self.url ) {
        self.vars[@"url"] = self.url;
    }
    if ( self.metaDescription ) {
        self.vars[@"meta-description"] = self.metaDescription;
    }

    self.vars[@"sidebar"] = @"";

    return [super presentViewControllerWithRequest:request response:response];
}

@end
