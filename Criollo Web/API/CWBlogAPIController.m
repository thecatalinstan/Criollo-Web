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
#define CWBlogAPIRelatedPostsPath       @"/related/:pid"

#define CWBlogAPITagsPath               @"/tags"
#define CWBlogAPISearchTagsPath         @"/tags/search"
#define CWBlogAPISingleTagPath          @"/tags/:tid"

#define CWBlogAPIMakeHandlePath         @"/make-handle"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogAPIController ()

- (void)setupRoutes;

@end

NS_ASSUME_NONNULL_END

@implementation CWBlogAPIController

- (instancetype)initWithPrefix:(NSString *)prefix {
    self = [super initWithPrefix:prefix];
    if ( self != nil ) {
        [self setupRoutes];
    }
    return self;
}

#pragma mark - Routing

- (void)setupRoutes {

    // Get post block
    [self get:CWBlogAPISinglePostPath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString* pid = request.query[@"pid"];
        CWBlogPost* post;;
        if (!(post = [CWBlogPost getByUID:pid])) {
            [response setStatusCode:404 description:nil];
            [CWAPIController failWithError:nil request:request response:response];
        }
        
        [CWAPIController succeedWithPayload:post.modelObject.toDictionary request:request response:response];
    }}];

    [self delete:CWBlogAPISinglePostPath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {        
        NSError *error = [NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorNotImplemented userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Not implemented",)}];
        [CWAPIController failWithError:error request:request response:response];
    }}];

    CRRouteBlock createOrUpdatePostBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSError *error;
        
        CWAPIBlogPost *receivedPost;
        if (!(receivedPost = [[CWAPIBlogPost alloc] initWithDictionary:request.body error:&error])) {
            [CWAPIController failWithError:error request:request response:response];
            return;
        }
        
        NSString *renderedContent;
        if (!(renderedContent = [CWBlog renderMarkdown:receivedPost.content error:&error])) {
            [CWAPIController failWithError:error request:request response:response];
            return;
        }
        
        // Auto-generate the excerpt if there is none.
        NSString *excerpt = receivedPost.excerpt;
        if ([excerpt stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0 &&
            !(excerpt = [CWBlog excerptFromHTML:renderedContent error:&error])) {
            [CWAPIController failWithError:error request:request response:response];
            return;
        }
        
        NSString *username;
        if (!(username = receivedPost.author.user)) {
            CWUser* currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
            username = currentUser.username;
        }
        
        CWBlogAuthor *author;
        if (!(author = [CWBlogAuthor getByUser:username])) {
            error = [NSError errorWithDomain:CWBlogErrorDomain code:CWBlogUnknownAuthor userInfo:nil];
            [CWAPIController failWithError:error request:request response:response];
            return;
        }
        
        RLMRealm *realm = [CWBlog realm];
        [realm beginWriteTransaction];
        
        CWBlogPost* post = (CWBlogPost *)receivedPost.schemaObject;
        post.renderedContent = renderedContent;
        post.excerpt = excerpt;
        post.author = author;
        post.lastUpdatedDate = [NSDate date];
        if (!post.publishedDate) {
            post.publishedDate = [NSDate date];
        }
        if (post.handle.length == 0) {
            post.handle = post.title.URLFriendlyHandle;
        }
        for (CWBlogTag* tag in post.tags) {
            tag.handle = tag.name.URLFriendlyHandle;
            [realm addOrUpdateObject:tag];
        }
        
        [realm addOrUpdateObject:post];
        if (![realm commitWriteTransaction:&error]) {
            [CWAPIController failWithError:error request:request response:response];
            return;
        }
        
        [CWAPIController succeedWithPayload:post.modelObject.toDictionary request:request response:response];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CWRoutesChangedNotificationName object:nil];
    }};
    [self put:CWBlogAPIPostsPath block:createOrUpdatePostBlock];
    [self post:CWBlogAPIPostsPath block:createOrUpdatePostBlock];

    // Related posts
    [self get:CWBlogAPIRelatedPostsPath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString *pid = request.query[@"pid"];
        
        CWBlogPost *post;
        if (!(post = [CWBlogPost getByUID:pid])) {
            [response setStatusCode:404 description:nil];
            [CWAPIController failWithError:nil request:request response:response];
            return;
        }
        
        NSArray<CWBlogPost *> *relatedPosts = [CWBlog relatedPostsForPost:post];
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:relatedPosts.count];
        [relatedPosts enumerateObjectsUsingBlock:^(CWBlogPost * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [results addObject:obj.modelObject.toDictionary];
        }];
        
        [CWAPIController succeedWithPayload:results request:request response:response];
    }}];

    // Search tags
    [self add:CWBlogAPISearchTagsPath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString *q = request.query[@"q"];
        
        RLMResults *tags = [[CWBlogTag getObjectsWhere:@"name contains[c] %@", q] sortedResultsUsingKeyPath:@"name" ascending:YES];
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:tags.count];
        for (CWBlogTag *tag in tags) {
            [result addObject:tag.modelObject.toDictionary];
        }
        
        [CWAPIController succeedWithPayload:result request:request response:response];
    }}];

    // Make handle
    [self add:CWBlogAPIMakeHandlePath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString *input = request.query[@"input"];
        [CWAPIController succeedWithPayload:input.URLFriendlyHandle request:request response:response];
    }}];

    [self get:CWBlogAPISingleTagPath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString *tid = request.query[@"tid"];
        
        CWBlogTag *tag;
        if (!(tag = [CWBlogTag getByUID:tid])) {
            [response setStatusCode:404 description:nil];
            [CWAPIController failWithError:nil request:request response:response];
            return;
        }
        [CWAPIController succeedWithPayload:tag.modelObject.toDictionary request:request response:response];
    }}];

    [self delete:CWBlogAPISingleTagPath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSError *error = [NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorNotImplemented userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Not implemented",)}];
        [CWAPIController failWithError:error request:request response:response];
    }}];

    CRRouteBlock createOrUpdateTagBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSError* error;
        CWAPIBlogTag *receivedTag;
        if (!(receivedTag = [[CWAPIBlogTag alloc] initWithDictionary:request.body error:&error])) {
            [CWAPIController failWithError:error request:request response:response];
            return;
        }
        
        RLMRealm *realm = [CWBlog realm];
        [realm beginWriteTransaction];
        
        CWBlogTag *tag = (CWBlogTag *)receivedTag.schemaObject;
        tag.handle = tag.name.URLFriendlyHandle;
        
        [realm addOrUpdateObject:tag];
        if (![realm commitWriteTransaction:&error]) {
            [CWAPIController failWithError:error request:request response:response];
        }

        [CWAPIController succeedWithPayload:tag.modelObject.toDictionary request:request response:response];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CWRoutesChangedNotificationName object:nil];
        
    }};
    [self put:CWBlogAPITagsPath block:createOrUpdateTagBlock];
    [self post:CWBlogAPITagsPath block:createOrUpdateTagBlock];
}

@end
