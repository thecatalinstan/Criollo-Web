//
//  CWBlogAPIController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 21/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <MMMarkdown/MMMarkdown.h>

#import "CWBlogAPIController.h"
#import "CWAPIController.h"
#import "CWAPIError.h"
#import "CWUser.h"
#import "CWAPIBlogTag.h"
#import "CWAPIBlogAuthor.h"
#import "CWAPIBlogPost.h"
#import "CWBlogTag.h"
#import "CWBlogAuthor.h"
#import "CWBlogPost.h"
#import "CWBlog.h"
#import "CWAppDelegate.h"
#import "NSString+URLUtils.h"

#define CWBlogAPIPostsPath              @"/posts"
#define CWBlogAPIPostsYearPath          @"/posts/:year"
#define CWBlogAPIPostsYearMonthPath     @"/posts/:year/:month"
#define CWBlogAPISinglePostPath         @"/posts/:year/:month/:handle"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogAPIController ()

@property (nonatomic, strong, readonly) dispatch_queue_t isolationQueue;

@property (nonatomic, strong, readonly) CRRouteBlock getPostsBlock;
@property (nonatomic, strong, readonly) CRRouteBlock getPostBlock;
@property (nonatomic, strong, readonly) CRRouteBlock deletePostBlock;
@property (nonatomic, strong, readonly) CRRouteBlock createOrUpdatePostBlock;


- (void)setupRoutes;

@end

NS_ASSUME_NONNULL_END

@implementation CWBlogAPIController

+ (instancetype)sharedController {
    static CWBlogAPIController* sharedController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[CWBlogAPIController alloc] initWithPrefix:CWAPIBlogPath];
    });
    return sharedController;
}

- (instancetype)initWithPrefix:(NSString *)prefix {
    self = [super initWithPrefix:prefix];
    if ( self != nil ) {
        _isolationQueue = dispatch_queue_create([[NSStringFromClass(self.class) stringByAppendingPathExtension:@"IsolationQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_isolationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
        [self setupRoutes];
    }
    return self;
}

#pragma mark - Routing

- (void)setupRoutes {

    // Get posts block
    [self get:CWBlogAPIPostsPath block:self.getPostsBlock];
    [self get:CWBlogAPIPostsYearPath block:self.getPostsBlock];
    [self get:CWBlogAPIPostsYearMonthPath block:self.getPostsBlock];

    // Get single post by year, month, handle
    [self get:CWBlogAPISinglePostPath block:self.getPostBlock];

    // Delete post by year, month, handle
    [self delete:CWBlogAPISinglePostPath block:self.deletePostBlock];

    // Create post
    [self put:CWBlogAPIPostsPath block:self.createOrUpdatePostBlock];

    // Update post
    [self post:CWBlogAPIPostsPath block:self.createOrUpdatePostBlock];
}

- (CRRouteBlock)getPostsBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
//
//        // Get the month and year from the path
//        NSUInteger year = request.query[@"year"].integerValue;
//        NSUInteger month = request.query[@"month"].integerValue;
//
//        CWBlogArchivePeriod period = [CWBlog parseYear:year month:month];
//        NSPredicate* fetchPredicate;
//        if ( period.year != 0 ) {
//            // Build a predicate
//            CWBlogDatePair *datePair = [CWBlog datePairWithYearMonth:period];
//            fetchPredicate = [NSPredicate predicateWithFormat:@"date >= %@ and date <= %@", datePair.startDate, datePair.endDate];
//        }
//
//        __block NSError * error = nil;
//        NSMutableArray<NSDictionary *> * results = [NSMutableArray array];
//        [[CWAppDelegate sharedBlog].managedObjectContext performBlockAndWait:^{
//            NSArray<CWBlogPost *> * posts = [CWBlogPost fetchBlogPostsWithPredicate:fetchPredicate error:&error];
//            [posts enumerateObjectsUsingBlock:^(CWBlogPost *  _Nonnull post, NSUInteger idx, BOOL * _Nonnull stop) {
//                CWAPIBlogPost * apiPost = post.APIBlogPost;
//                [results addObject:apiPost.toDictionary];
//            }];
//        }];
//        if ( error != nil ) {
//            [CRApp logFormat:@"Error fetching posts: %@", error];
//            [CWAPIController failWithError:error request:request response:response];
//        } else {
//            [CWAPIController succeedWithPayload:results request:request response:response];
//            completionHandler();
//        }
    };
}

- (CRRouteBlock)getPostBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
//        NSUInteger year = request.query[@"year"].integerValue;
//        NSUInteger month = request.query[@"month"].integerValue;
//        NSString* handle = request.query[@"handle"];
//
//        [[CWAppDelegate sharedBlog].managedObjectContext performBlockAndWait:^{
//            CWBlogPost* post = [CWBlogPost blogPostWithHandle:handle year:year month:month];
//            if (post != nil) {
//                [CWAPIController succeedWithPayload:post.APIBlogPost.toDictionary request:request response:response];
//                completionHandler();
//            } else {
//                [response setStatusCode:404 description:nil];
//                [CWAPIController failWithError:nil request:request response:response];
//            }
//        }];
    };
}

- (CRRouteBlock)deletePostBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSError *error = [NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorNotImplemented userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Not implemented",)}];
        [CWAPIController failWithError:error request:request response:response];
        completionHandler();

//        NSUInteger year = request.query[@"year"].integerValue;
//        NSUInteger month = request.query[@"month"].integerValue;
//        NSString* handle = request.query[@"handle"];
//
//        [[CWAppDelegate sharedBlog].managedObjectContext performBlockAndWait:^{
//            CWBlogPost* post = [CWBlogPost blogPostWithHandle:handle year:year month:month];
//            if (post != nil) {
//                [CWAPIController succeedWithPayload:post.APIBlogPost.toDictionary request:request response:response];
//                completionHandler();
//            } else {
//                [response setStatusCode:404 description:nil];
//                [CWAPIController failWithError:nil request:request response:response];
//            }
//        }];
    };
}

- (CRRouteBlock)createOrUpdatePostBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
//        __block CWBlogPost* post;
//        __block CWAPIBlogPost* responsePost;
//        __block NSError* error;
//       __block  BOOL shouldFail = NO;
//        CWAPIBlogPost* apiPost = [[CWAPIBlogPost alloc] initWithDictionary:request.body error:&error];
//        if ( error ) {
//            shouldFail = YES;
//        } else {
//            error = nil;
//            NSString* renderedContent = [MMMarkdown HTMLStringWithMarkdown:apiPost.content error:&error];
//            if ( error ) {
//                shouldFail = YES;
//            } else {
//                [[CWAppDelegate sharedBlog].managedObjectContext performBlockAndWait:^{
//                    post = [CWBlogPost blogPostFromAPIBlogPost:apiPost];
//                    post.renderedContent = renderedContent;
//                    post.date = [NSDate date];
//                    post.handle = post.title.URLFriendlyHandle;
//
//                    CWUser* currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
//
//                    error = nil;
//                    CWBlogAuthor* author = [CWBlogAuthor authorWithUsername:currentUser.username];
//                    if ( author == nil ) {
//                        shouldFail = YES;
//                    } else {
//                        post.author = author;
//                        error = nil;
//                        [[CWAppDelegate sharedBlog] saveManagedObjectContext:&error];
//                        if ( error ) {
//                            shouldFail = YES;
//                        } else {
//                            responsePost = post.APIBlogPost;
//                        }
//                    }
//                }];
//            }
//        }
//
//        if ( shouldFail ) {
//            [CWAPIController failWithError:error request:request response:response];
//        } else {
//            [CWAPIController succeedWithPayload:responsePost request:request response:response];
//            completionHandler();
//        }
    };
}


@end
