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

#define CWBlogAPIPostsPath          @"/posts"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogAPIController ()

@property (nonatomic, strong, readonly) dispatch_queue_t isolationQueue;

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

    [self addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CWUser* currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
        if ( !currentUser ) {
            NSError* error = [NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorUnauthorized userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"You are not authorized.",)}];
            [CWAPIController failWithError:error request:request response:response];
        } else {
            completionHandler();
        }
    }];

    // Get all posts
    [self addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSError * error = nil;
        NSArray<CWBlogPost *> * posts = [CWBlogPost fetchBlogPostsWithPredicate:nil error:&error];
        NSMutableArray<NSDictionary *> * results = [NSMutableArray arrayWithCapacity:posts.count];
        [[CWAppDelegate sharedBlog].managedObjectContext performBlockAndWait:^{
            [posts enumerateObjectsUsingBlock:^(CWBlogPost *  _Nonnull post, NSUInteger idx, BOOL * _Nonnull stop) {
                CWAPIBlogPost * apiPost = post.APIBlogPost;
                [results addObject:apiPost.toDictionary];
            }];
        }];
        [CWAPIController succeedWithPayload:results request:request response:response];
        completionHandler();
    } forPath:CWBlogAPIPostsPath HTTPMethod:CRHTTPMethodGet];

    // Delete post
    [self addBlock:self.deleteBlogPostBlock forPath:CWBlogAPIPostsPath HTTPMethod:CRHTTPMethodDelete];

    // Create post
    [self addBlock:self.createOrUpdatePostBlock forPath:CWBlogAPIPostsPath HTTPMethod:CRHTTPMethodPut];

    // Update post
    [self addBlock:self.createOrUpdatePostBlock forPath:CWBlogAPIPostsPath HTTPMethod:CRHTTPMethodPost];
}

- (CRRouteBlock)deleteBlogPostBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSError *error = [NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorNotImplemented userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Not implemented",)}];
        [CWAPIController failWithError:error request:request response:response];
        completionHandler();
    };
}

- (CRRouteBlock)createOrUpdatePostBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        __block CWBlogPost* post;
        __block CWAPIBlogPost* responsePost;
        __block NSError* error;
       __block  BOOL shouldFail = NO;
        CWAPIBlogPost* apiPost = [[CWAPIBlogPost alloc] initWithDictionary:request.body error:&error];
        if ( error ) {
            shouldFail = YES;
        } else {
            error = nil;
            NSString* renderedContent = [MMMarkdown HTMLStringWithMarkdown:apiPost.content error:&error];
            if ( error ) {
                shouldFail = YES;
            } else {
                [[CWAppDelegate sharedBlog].managedObjectContext performBlockAndWait:^{
                    post = [CWBlogPost blogPostFromAPIBlogPost:apiPost];
                    post.renderedContent = renderedContent;
                    post.date = [NSDate date];
                    post.handle = post.title.URLFriendlyHandle;

                    CWUser* currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];

                    error = nil;
                    CWBlogAuthor* author = [CWBlogAuthor fetchAuthorForUsername:currentUser.username error:&error];
                    if ( error ) {
                        shouldFail = YES;
                    } else {
                        post.author = author;
                        error = nil;
                        [[CWAppDelegate sharedBlog] saveManagedObjectContext:&error];
                        if ( error ) {
                            shouldFail = YES;
                        } else {
                            responsePost = post.APIBlogPost;
                        }
                    }
                }];
            }
        }

        if ( shouldFail ) {
            [CWAPIController failWithError:error request:request response:response];
        } else {
            [CWAPIController succeedWithPayload:responsePost request:request response:response];
            completionHandler();
        }
    };
}


@end
