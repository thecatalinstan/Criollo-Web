//
//  CWBlogAPIController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 21/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

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
#define CWBlogAPISinglePostPath         @"/posts/:pid"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogAPIController ()

@property (nonatomic, strong, readonly) dispatch_queue_t isolationQueue;

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
    // Get single post
    [self get:CWBlogAPISinglePostPath block:self.getPostBlock];

    // Delete post
    [self delete:CWBlogAPISinglePostPath block:self.deletePostBlock];

    // Create post
    [self put:CWBlogAPIPostsPath block:self.createOrUpdatePostBlock];

    // Update post
    [self post:CWBlogAPIPostsPath block:self.createOrUpdatePostBlock];
}

- (CRRouteBlock)getPostBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* pid = request.query[@"pid"];

        CWBlogPost* post = [CWBlogPost getByUID:pid];
        if (post != nil) {
            [CWAPIController succeedWithPayload:post.modelObject.toDictionary request:request response:response];
            completionHandler();
        } else {
            [response setStatusCode:404 description:nil];
            [CWAPIController failWithError:nil request:request response:response];
        }
    };
}

- (CRRouteBlock)deletePostBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSError *error = [NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorNotImplemented userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Not implemented",)}];
        [CWAPIController failWithError:error request:request response:response];
        completionHandler();
    };
}

- (CRRouteBlock)createOrUpdatePostBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

        NSError* error = nil;
        CWAPIBlogPost* receivedPost = [[CWAPIBlogPost alloc] initWithDictionary:request.body error:&error];
        if ( error ) {
            [CWAPIController failWithError:error request:request response:response];
            return;
        }

        NSString* renderedContent = [CWBlog renderMarkdown:receivedPost.content error:&error];
        if ( error ) {
            [CWAPIController failWithError:error request:request response:response];
            return;
        }

        // Auto-generate the excerpt if there is none.
        NSString* excerpt = receivedPost.excerpt;
        if ( [excerpt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0 ) {
            excerpt = [CWBlog excerptFromHTML:renderedContent error:&error];
        }

        NSString * username = receivedPost.author.user;
        if ( !username ) {
            CWUser* currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
            username = currentUser.username;
        }

        CWBlogAuthor* author = [CWBlogAuthor getByUser:username];
        if ( author == nil ) {
            error = [NSError errorWithDomain:CWBlogErrorDomain code:CWBlogUnknownAuthor userInfo:nil];
            [CWAPIController failWithError:nil request:request response:response];
            return;
        }

        RLMRealm *realm = [CWBlog realm];
        [realm beginWriteTransaction];

        CWBlogPost* post = (CWBlogPost *)receivedPost.schemaObject;
        post.renderedContent = renderedContent;
        post.excerpt = excerpt;
        post.date = [NSDate date];
        post.handle = post.title.URLFriendlyHandle;
        post.author = author;

        [realm addOrUpdateObject:post];
        if ( [realm commitWriteTransaction:&error] ) {
            [CWAPIController succeedWithPayload:post.modelObject.toDictionary request:request response:response];
            completionHandler();
        } else {
            [CWAPIController failWithError:error request:request response:response];
        }

    };
}


@end
