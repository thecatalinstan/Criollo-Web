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

#define CWBlogNewPostPredicate      @"new"
#define CWBlogArchivePredicate      @"archive"
#define CWBlogTagPredicate          @"tag"
//#define CWBlogCategoryPredicate     @"category"
#define CWBlogAuthorPredicate       @"author"
#define CWBlogNewPostPathPattern    @"^/blog/[0-9]{4}/[0-9]{2}/[a-zA-Z-]+"

@interface CWBlogViewController ()

- (NSRegularExpression *)blogPathRegularExpression;

@end

@implementation CWBlogViewController

- (NSRegularExpression *)blogPathRegularExpression {
    static NSRegularExpression *blogPostRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError* regexError;
        blogPostRegex = [NSRegularExpression regularExpressionWithPattern:CWBlogNewPostPathPattern options:NSRegularExpressionCaseInsensitive|NSRegularExpressionIgnoreMetacharacters error:&regexError];
        if ( regexError ) {
            [CRApp logErrorFormat:@"%@", regexError];
        }
    });
    return blogPostRegex;
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {

    NSMutableString* contents = [NSMutableString string];

    // Check for the path to a post
    if ( [self.blogPathRegularExpression numberOfMatchesInString:request.URL.path options:0 range:NSMakeRange(0, request.URL.path.length)] == 1 ) {

        NSUInteger year = request.URL.pathComponents[2].integerValue;
        NSUInteger month = request.URL.pathComponents[3].integerValue;
        NSString* handle = request.URL.pathComponents[4].lowercaseString.stringByRemovingPercentEncoding;
        CWBlogPost* post = [CWBlogPost blogPostWithHandle:handle year:year month:month];
        if (post == nil) {
            [contents appendString:@"Not Found :("];
        } else {
            [contents appendString:[[[CWBlogPostDetailsViewController alloc] initWithNibName:nil bundle:nil post:post] presentViewControllerWithRequest:request response:response]];
        }

    } else {
        NSString* predicate = request.URL.pathComponents.count > 2 ? request.URL.pathComponents[2] : @"";

        // New post
        if ( [predicate isEqualToString:CWBlogNewPostPredicate] ) {
            CWUser* currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
            if ( currentUser ) {
                [contents appendString:[[[CWBlogPostDetailsViewController alloc] initWithNibName:nil bundle:nil post:nil] presentViewControllerWithRequest:request response:response]];
            } else {
                [response setStatusCode:301 description:nil];
                [response setValue:CWBlogPath forHTTPHeaderField:@"Location"];
                return nil;
            }
        } else {
            // All the other oredicates require a payload, so redirect if we don't have one
            NSString* payload = request.URL.pathComponents.count > 3 ? request.URL.pathComponents[3] : @"";
            if ( payload.length == 0 && ([predicate isEqualToString:CWBlogTagPredicate] || [predicate isEqualToString:CWBlogAuthorPredicate]) ) {
                [response setStatusCode:301 description:nil];
                [response setValue:CWBlogPath forHTTPHeaderField:@"Location"];
                return nil;
            }

            NSPredicate *fetchPredicate = nil;

            if ( [predicate isEqualToString:CWBlogArchivePredicate] ) {
                // Get the month and year from the path
                NSUInteger year = request.URL.pathComponents.count >= 4 ? request.URL.pathComponents[3].integerValue : 0;

                if ( year > 0 ) {
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
                    fetchPredicate = [NSPredicate predicateWithFormat:@"date >= %@ and date <= %@", startDate, endDate];
                }
            } else if ( [predicate isEqualToString:CWBlogTagPredicate]) {
                NSString* tag = request.URL.pathComponents[3].stringByRemovingPercentEncoding;
                fetchPredicate = [NSPredicate predicateWithFormat:@"tag.name = %@", tag];
//            } else if ( [predicate isEqualToString:CWBlogCategoryPredicate] ) {
//                NSString* category = request.URL.pathComponents[3].stringByRemovingPercentEncoding;
//                fetchPredicate = [NSPredicate predicateWithFormat:@"category.name = %@", category];
            } else if ( [predicate isEqualToString:CWBlogAuthorPredicate] ) {
                NSString* author = request.URL.pathComponents[3].stringByRemovingPercentEncoding;
                fetchPredicate = [NSPredicate predicateWithFormat:@"author.user = %@", author];
            }

            NSError * error = nil;
            NSArray<CWBlogPost *> * posts = [CWBlogPost blogPostsWithPredicate:fetchPredicate error:&error];
            if (posts.count == 0) {
                [contents appendFormat:@"<p>%@</p>", @"There are no posts to show for now :("];
                // Check if there is a user and link to "add post"
                CWUser* currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
                if ( currentUser ) {
                    [contents appendFormat:@"<p><a href=\"%@/new\">Add a new post</a>", CWBlogPath];
                    if ( error.localizedDescription ) {
                        [contents appendFormat:@"<h3>%@</h3>", error.localizedDescription];
                        if ( error.userInfo ) {
                            [contents appendFormat:@"<pre>%@</pre>", error.userInfo];
                        }
                    }
                }
    
            } else {
                [posts enumerateObjectsUsingBlock:^(CWBlogPost *  _Nonnull post, NSUInteger idx, BOOL * _Nonnull stop) {
                    CWBlogPostViewController* postViewController = [[CWBlogPostViewController alloc] initWithNibName:nil bundle:nil post:post];
                    [contents appendString:[postViewController presentViewControllerWithRequest:request response:response]];
                }];
            }
        }
    }

    self.templateVariables[@"posts"] = contents;
    self.templateVariables[@"sidebar"] = @"";

    return [super presentViewControllerWithRequest:request response:response];
}

@end
