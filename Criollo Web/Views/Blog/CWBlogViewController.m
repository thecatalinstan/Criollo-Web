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

@property (nonatomic, strong, readonly) CRRouteBlock authCheckBlock;
@property (nonatomic, strong, readonly) CRRouteBlock payloadCheckBlock;
@property (nonatomic, strong, readonly) CRRouteBlock archiveBlock;
@property (nonatomic, strong, readonly) CRRouteBlock tagBlock;
@property (nonatomic, strong, readonly) CRRouteBlock authorBlock;
@property (nonatomic, strong, readonly) CRRouteBlock newPostBlock;
@property (nonatomic, strong, readonly) CRRouteBlock singlePostBlock;
@property (nonatomic, strong, readonly) CRRouteBlock enumeratePostsBlock;
@property (nonatomic, strong, readonly) CRRouteBlock presentViewControllerBlock;
@property (nonatomic, strong, readonly) CRRouteBlock noContentsBlock;

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

    // Feed
    [self add:CWBlogFeedPath controller:[CWBlogRSSController class] recursive:YES method:CRHTTPMethodGet];

    // New post
    [self get:CWBlogNewPostPath block:self.authCheckBlock];
    [self get:CWBlogNewPostPath block:self.newPostBlock];
    [self get:CWBlogNewPostPath block:self.noContentsBlock];
    [self get:CWBlogNewPostPath block:self.presentViewControllerBlock];

    // Author
    NSString* authorPath = [CWBlogAuthorPath stringByAppendingPathComponent:@":author"];
    [self get:authorPath block:self.authorBlock];
    [self get:authorPath block:self.enumeratePostsBlock];
    [self get:authorPath block:self.noContentsBlock];
    [self get:authorPath block:self.presentViewControllerBlock];

    // Tag
    NSString* tagPath = [CWBlogTagPath stringByAppendingPathComponent:@":tag"];
    [self get:tagPath block:self.tagBlock];
    [self get:tagPath block:self.enumeratePostsBlock];
    [self get:tagPath block:self.noContentsBlock];
    [self get:tagPath block:self.presentViewControllerBlock];

//    // Archive Index
//    [self get:CWBlogArchivePath block:self.archiveIndexBlock];

    // Yearly archive
    [self get:CWBlogArchiveYearPath block:self.archiveBlock];
    [self get:CWBlogArchiveYearPath block:self.enumeratePostsBlock];
    [self get:CWBlogArchiveYearPath block:self.noContentsBlock];
    [self get:CWBlogArchiveYearPath block:self.presentViewControllerBlock];

    // Monthly archive
    [self get:CWBlogArchiveYearMonthPath block:self.archiveBlock];
    [self get:CWBlogArchiveYearMonthPath block:self.enumeratePostsBlock];
    [self get:CWBlogArchiveYearMonthPath block:self.noContentsBlock];
    [self get:CWBlogArchiveYearMonthPath block:self.presentViewControllerBlock];

    // Single post
    [self get:CWBlogSinglePostPath block:self.singlePostBlock];
    [self get:CWBlogSinglePostPath block:self.noContentsBlock];
    [self get:CWBlogSinglePostPath block:self.presentViewControllerBlock];

    // Edit post
    [self get:CWBlogEditPostPath block:self.singlePostBlock];
    [self get:CWBlogEditPostPath block:self.noContentsBlock];
    [self get:CWBlogEditPostPath block:self.presentViewControllerBlock];

    // Default bblog page
    [self get:@"/" block:self.enumeratePostsBlock];
    [self get:@"/" block:self.noContentsBlock];
    [self get:@"/" block:self.presentViewControllerBlock];
}

#pragma mark - Route Handlers

/**
 *  Checks if a user is logged in and redirects to the login page
 */
- (CRRouteBlock)authCheckBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CWUser* currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
        if ( !currentUser ) {
            NSString* redirectLocation = [NSString stringWithFormat:@"%@?redirect=%@", CWLoginPath, [request.URL.absoluteURL.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            [response redirectToLocation:redirectLocation];
            return;
        }
        completionHandler();
    };
}

/**
 *  Checks if there is a payload (anything after the registered path
 */
- (CRRouteBlock)payloadCheckBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* payload = request.URL.pathComponents.count > 3 ? request.URL.pathComponents[3] : @"";
        if ( payload.length == 0 ) {
            [response redirectToLocation:CWBlogPath];
            return;
        }
        completionHandler();
    };
}

/**
 *  Generates the fetchPredicate used for the post archive
 */
- (CRRouteBlock)archiveBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

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
        self.fetchPredicate = [NSPredicate predicateWithFormat:@"publishedDate >= %@ and publishedDate <= %@ and published = true", datePair.startDate, datePair.endDate];

        // Set the page title
        NSString* humanReadableMonth = @"";
        if ( period.month != 0 ) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MMMM"];
            humanReadableMonth = [NSString stringWithFormat:@" %@ of", [formatter stringFromDate:datePair.startDate]];
        }
        NSString* humanReadableYear = period.year > 0 ? [NSString stringWithFormat:@" %lu", period.year] : @"";
        self.title = [NSString stringWithFormat:@"Posts published during%@%@", humanReadableMonth, humanReadableYear];
        self.showPageTitle = YES;

        completionHandler();
    };
}

/**
 *  Generates the fetchPredicate used for the tag post list
 */
- (CRRouteBlock)tagBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* handle = request.query[@"tag"];
        self.fetchPredicate = [NSPredicate predicateWithFormat:@"ANY tags.handle = %@ and published = true", handle];
        CWBlogTag* tag = [CWBlogTag getByHandle:handle];
        if ( tag ) {
            self.title = [NSString stringWithFormat:@"Posts tagged ”%@“", tag.name];
            self.showPageTitle = YES;
        }
        completionHandler();
    };
}

/**
 *  Generates the fetchPredicate used for the author post list
 */
- (CRRouteBlock)authorBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* handle = request.query[@"author"];
        self.fetchPredicate = [NSPredicate predicateWithFormat:@"author.handle = %@ and published = true", handle];
        CWBlogAuthor* author = [CWBlogAuthor getByHandle:handle];
        if ( author ) {
            self.title = [NSString stringWithFormat:@"Posts by %@", author.displayName];
            self.showPageTitle = YES;
        }
        completionHandler();
    };
}

/**
 *  Displays the "new" post editing form
 */
- (CRRouteBlock)newPostBlock {
    return^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [self.contents appendString:[[[CWBlogPostDetailsViewController alloc] initWithNibName:nil bundle:nil post:nil] presentViewControllerWithRequest:request response:response]];
        self.title = @"Create New Blog Post";
        self.showPageTitle = NO;
        completionHandler();
    };
}

/**
 *  Displays a single blog post in full
 */
- (CRRouteBlock)singlePostBlock {
    return^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSUInteger year = (request.query[@"year"] ? : request.query[@"0"]).integerValue;
        NSUInteger month = (request.query[@"month"] ? : request.query[@"1"]).integerValue;
        NSString* handle = request.query[@"handle"] ? : request.query[@"2"];
        CWBlogPost* post = [CWBlogPost getByHandle:handle year:year month:month];
        if (post != nil) {
            [self.contents appendString:[[[CWBlogPostDetailsViewController alloc] initWithNibName:nil bundle:nil post:post] presentViewControllerWithRequest:request response:response]];
            self.title = post.title;
            self.ogType = @"article";
            self.metaDescription = post.excerpt;
            self.url = [post permalinkForRequest:request];
            self.showPageTitle = NO;
        }
        completionHandler();
    };
}

/**
 *  Actually fetches the posts according to the fetchPredicate and displays the list
 */
- (CRRouteBlock)enumeratePostsBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        RLMResults* posts = [[CWBlogPost getObjectsWithPredicate:self.fetchPredicate] sortedResultsUsingProperty:@"publishedDate" ascending:NO];
        for ( CWBlogPost *post in posts ) {
            CWBlogPostViewController* postViewController = [[CWBlogPostViewController alloc] initWithNibName:nil bundle:nil post:post];
            [self.contents appendString:[postViewController presentViewControllerWithRequest:request response:response]];
        }
        completionHandler();
    };
}

/**
 *  Checks if there is any content to display and prints out some text
 */
- (CRRouteBlock)noContentsBlock {
    return^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

        // Bailout early if there's some contents
        if ( self.contents.length != 0 ) {
            completionHandler();
            return;
        }
        [self.contents appendFormat:@"<p>%@</p>", @"There are no posts to show for now :("];

        // Check if there is a user and link to "add post"
        CWUser* currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
        if ( !currentUser ) {
            completionHandler();
            return;
        }

        [self.contents appendFormat:@"<p><a href=\"%@%@\">Add a new post</a>", CWBlogPath, CWBlogNewPostPath];
        completionHandler();
    };
}

/**
 *  Invokes the controller's presentViewControllerWithRequest:response: method and finishes the response
 */
- (CRRouteBlock)presentViewControllerBlock {
    return^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response sendString:[self presentViewControllerWithRequest:request response:response]];
        completionHandler();
    };
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
