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
#import "CWBlogPost.h"
#import "CWUser.h"
#import "CWAPIController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogViewController ()

@property (nonatomic, strong, readonly) NSMutableString* contents;
@property (nonatomic, strong) NSPredicate* fetchPredicate;

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
    [self addBlock:self.payloadCheckBlock forPath:CWBlogAuthorPath];
    [self addBlock:self.authorBlock forPath:CWBlogAuthorPath];
    [self addBlock:self.enumeratePostsBlock forPath:CWBlogAuthorPath];

    // Tag
    [self addBlock:self.payloadCheckBlock forPath:CWBlogTagPath];
    [self addBlock:self.tagBlock forPath:CWBlogTagPath];
    [self addBlock:self.enumeratePostsBlock forPath:CWBlogTagPath];

    // Archive
    [self addBlock:self.payloadCheckBlock forPath:CWBlogArchivePath];
    [self addBlock:self.archiveBlock forPath:CWBlogArchivePath];
    [self addBlock:self.enumeratePostsBlock forPath:CWBlogArchivePath];

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
        
        completionHandler();
    };
}

- (CRRouteBlock)tagBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* tag = request.URL.pathComponents[3].stringByRemovingPercentEncoding;
        self.fetchPredicate = [NSPredicate predicateWithFormat:@"tag.name = %@", tag];
    };
}

- (CRRouteBlock)authorBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* author = request.URL.pathComponents[3].stringByRemovingPercentEncoding;
        self.fetchPredicate = [NSPredicate predicateWithFormat:@"author.user = %@", author];
    };
}

- (CRRouteBlock)newPostBlock {
    return^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CWBlogPostDetailsViewController* newPostViewController = [[CWBlogPostDetailsViewController alloc] initWithNibName:nil bundle:nil post:nil];
        NSString* responseString = [newPostViewController presentViewControllerWithRequest:request response:response];
        [self.contents appendString:responseString];
        completionHandler();
    };
}

- (CRRouteBlock)singlePostBlock {
    return^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSUInteger year = request.query[@"0"].integerValue;
        NSUInteger month = request.query[@"1"].integerValue;
        NSString* handle = request.query[@"2"];

        CWBlogPost* post = [CWBlogPost blogPostWithHandle:handle year:year month:month];
        if (post != nil) {
            [self.contents appendString:[[[CWBlogPostDetailsViewController alloc] initWithNibName:nil bundle:nil post:post] presentViewControllerWithRequest:request response:response]];
        }
        completionHandler();
    };
}

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

- (CRRouteBlock)presentViewControllerBlock {
    return^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response sendString:[self presentViewControllerWithRequest:request response:response]];
        completionHandler();
    };
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.vars[@"posts"] = self.contents;
    self.vars[@"sidebar"] = @"";
    return [super presentViewControllerWithRequest:request response:response];
}

@end
