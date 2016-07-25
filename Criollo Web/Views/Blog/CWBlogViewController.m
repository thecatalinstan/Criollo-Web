//
//  CWBlogViewController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 09/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlog.h"
#import "CWBlogViewController.h"
#import "CWBlogPostViewController.h"
#import "CWBlogPostDetailsViewController.h"
#import "CWAppDelegate.h"
#import "CWUser.h"
#import "CWAPIController.h"
#import "CWBlogPost.h"
#import "CWBlogAuthor.h"
#import "CWBlogTag.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogViewController ()

@property (nonatomic, strong, readonly) NSMutableString* contents;
@property (nonatomic, strong) NSPredicate* fetchPredicate;
@property (nonatomic, strong) NSString * title;

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
    }
    return self;
}

#pragma mark - Routing

- (void)setupRoutes {
    // New post
    [self addBlock:self.authCheckBlock forPath:CWBlogNewPostPath];
    [self addBlock:self.newPostBlock forPath:CWBlogNewPostPath];

    // Author
    [self addBlock:self.payloadCheckBlock forPath:CWBlogAuthorPath method:CRHTTPMethodAll recursive:YES];
    [self addBlock:self.authorBlock forPath:CWBlogAuthorPath method:CRHTTPMethodAll recursive:YES];
    [self addBlock:self.enumeratePostsBlock forPath:CWBlogAuthorPath method:CRHTTPMethodAll recursive:YES];

    // Tag
    [self addBlock:self.payloadCheckBlock forPath:CWBlogTagPath method:CRHTTPMethodAll recursive:YES];
    [self addBlock:self.tagBlock forPath:CWBlogTagPath method:CRHTTPMethodAll recursive:YES];
    [self addBlock:self.enumeratePostsBlock forPath:CWBlogTagPath method:CRHTTPMethodAll recursive:YES];

    // Archive
    [self addBlock:self.payloadCheckBlock forPath:CWBlogArchivePath method:CRHTTPMethodAll recursive:YES];
    [self addBlock:self.archiveBlock forPath:CWBlogArchivePath method:CRHTTPMethodAll recursive:YES];
    [self addBlock:self.enumeratePostsBlock forPath:CWBlogArchivePath method:CRHTTPMethodAll recursive:YES];

    // Single post
    [self addBlock:self.singlePostBlock forPath:CWBlogSinglePostPath];

    // Default bblog page
    [self addBlock:self.enumeratePostsBlock forPath:@"/"];

    // Fallback for blank contents
    [self addBlock:self.noContentsBlock];

    // Actually display the contents and finish the response
    [self addBlock:self.presentViewControllerBlock];
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
        NSUInteger year = request.URL.pathComponents.count >= 4 ? request.URL.pathComponents[3].integerValue : 0;
        if ( year == 0 ) {
            completionHandler();
            return;
        }

        NSUInteger month = request.URL.pathComponents.count >= 5 ? request.URL.pathComponents[4].integerValue : 0;
        if ( month == 0 || month > 12 ) {
            month = 0;
        }

        NSUInteger startYear, endYear, startMonth, endMonth;
        startYear = year;
        if ( month == 0 ) {
            startMonth = 1;
            endYear = ++year;
            endMonth = 1;
        } else {
            startMonth = month;
            if ( month == 12 ) {
                endMonth = 1;
                endYear = ++year;
            } else {
                endMonth = ++month;
                endYear = year;
            }
        }

        // Build a predicate
        NSDate* startDate = [[NSCalendar currentCalendar] dateWithEra:1 year:startYear month:startMonth day:1 hour:0 minute:0 second:0 nanosecond:0];
        NSDate* endDate = [[[NSCalendar currentCalendar] dateWithEra:1 year:endYear month:endMonth day:1 hour:0 minute:0 second:0 nanosecond:0] dateByAddingTimeInterval:-1];
        self.fetchPredicate = [NSPredicate predicateWithFormat:@"date >= %@ and date <= %@", startDate, endDate];

        // Set the page title
        NSString* humanReadableMonth = @"";
        if ( month != 0 ) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MMMM"];
            humanReadableMonth = [NSString stringWithFormat:@" %@", [formatter stringFromDate:startDate]];
        }
        NSString* humanReadableYear = year > 0 ? [NSString stringWithFormat:@" %lu", year] : @"";
        self.title = [NSString stringWithFormat:@"Posts Archive for%@%@", humanReadableMonth, humanReadableYear];
        
        completionHandler();
    };
}

/**
 *  Generates the fetchPredicate used for the tag post list
 */
- (CRRouteBlock)tagBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* tag = request.URL.pathComponents[3].stringByRemovingPercentEncoding;
        self.fetchPredicate = [NSPredicate predicateWithFormat:@"tag.name = %@", tag];
        self.title = [NSString stringWithFormat:@"Post for tag %@", tag];
        completionHandler();
    };
}

/**
 *  Generates the fetchPredicate used for the author post list
 */
- (CRRouteBlock)authorBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* authorHandle = request.URL.pathComponents[3].stringByRemovingPercentEncoding;
        self.fetchPredicate = [NSPredicate predicateWithFormat:@"author.user = %@", authorHandle];
        CWBlogAuthor* author = [CWBlogAuthor authorWithHandle:authorHandle];
        if ( author ) {
            self.title = [NSString stringWithFormat:@"Post by %@", author.displayName];
        }
        completionHandler();
    };
}

/**
 *  Displays the "new" post editing form
 */
- (CRRouteBlock)newPostBlock {
    return^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CWBlogPostDetailsViewController* newPostViewController = [[CWBlogPostDetailsViewController alloc] initWithNibName:nil bundle:nil post:nil];
        NSString* responseString = [newPostViewController presentViewControllerWithRequest:request response:response];
        [self.contents appendString:responseString];
        self.title = @"Create New Blog Post";
        completionHandler();
    };
}

/**
 *  Displays a single blog post in full
 */
- (CRRouteBlock)singlePostBlock {
    return^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSUInteger year = request.query[@"0"].integerValue;
        NSUInteger month = request.query[@"1"].integerValue;
        NSString* handle = request.query[@"2"];

        CWBlogPost* post = [CWBlogPost blogPostWithHandle:handle year:year month:month];
        if (post != nil) {
            [self.contents appendString:[[[CWBlogPostDetailsViewController alloc] initWithNibName:nil bundle:nil post:post] presentViewControllerWithRequest:request response:response]];
            [[CWAppDelegate sharedBlog].managedObjectContext performBlockAndWait:^{
                self.title = post.title;
            }];
        }
        completionHandler();
    };
}

/**
 *  Actually fetches the posts according to the fetchPredicate and displays the list
 */
- (CRRouteBlock)enumeratePostsBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSError * error = nil;
        NSArray<CWBlogPost *> * posts = [CWBlogPost fetchBlogPostsWithPredicate:self.fetchPredicate error:&error];
        [posts enumerateObjectsUsingBlock:^(CWBlogPost *  _Nonnull post, NSUInteger idx, BOOL * _Nonnull stop) {
            CWBlogPostViewController* postViewController = [[CWBlogPostViewController alloc] initWithNibName:nil bundle:nil post:post];
            [self.contents appendString:[postViewController presentViewControllerWithRequest:request response:response]];
        }];
        if ( error ) {
            [CRApp logErrorFormat:@"Error while fetching posts: %@", error];
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
    self.vars[@"posts"] = self.contents;
    self.vars[@"title"] = self.title;
    self.vars[@"sidebar"] = @"";
    return [super presentViewControllerWithRequest:request response:response];
}

@end
