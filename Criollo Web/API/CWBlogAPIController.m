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

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogAPIController ()

@property (nonatomic, strong, readonly) dispatch_queue_t isolationQueue;

@property (nonatomic, strong, readonly) CRRouteBlock getPostBlock;
@property (nonatomic, strong, readonly) CRRouteBlock deletePostBlock;
@property (nonatomic, strong, readonly) CRRouteBlock createOrUpdatePostBlock;
@property (nonatomic, strong, readonly) CRRouteBlock relatedPostsBlock;

@property (nonatomic, strong, readonly) CRRouteBlock getTagBlock;
@property (nonatomic, strong, readonly) CRRouteBlock deleteTagBlock;
@property (nonatomic, strong, readonly) CRRouteBlock createOrUpdateTagBlock;
@property (nonatomic, strong, readonly) CRRouteBlock searchTagsBlock;

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
    // Posts
    [self get:CWBlogAPISinglePostPath block:self.getPostBlock];
    [self delete:CWBlogAPISinglePostPath block:self.deletePostBlock];
    [self put:CWBlogAPIPostsPath block:self.createOrUpdatePostBlock];
    [self post:CWBlogAPIPostsPath block:self.createOrUpdatePostBlock];

    // Related posts
    [self get:CWBlogAPIRelatedPostsPath block:self.relatedPostsBlock];

    // Search tags
    [self get:CWBlogAPISearchTagsPath block:self.searchTagsBlock];
    [self post:CWBlogAPISearchTagsPath block:self.searchTagsBlock];

    // Tags
    [self get:CWBlogAPISingleTagPath block:self.getTagBlock];
    [self delete:CWBlogAPISingleTagPath block:self.deleteTagBlock];
    [self put:CWBlogAPITagsPath block:self.createOrUpdateTagBlock];
    [self post:CWBlogAPITagsPath block:self.createOrUpdateTagBlock];

}

#pragma mark - Posts

- (CRRouteBlock)getPostBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* pid = request.query[@"pid"];

        CWBlogPost* post = [CWBlogPost getByUID:pid];
        if (post != nil) {
            [CWAPIController succeedWithPayload:post.modelObject.toDictionary request:request response:response];
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
        if ( !post.publishedDate ) {
            post.publishedDate = [NSDate date];
        }
        post.lastUpdatedDate = [NSDate date];
        post.handle = post.title.URLFriendlyHandle;
        post.author = author;

        for ( CWBlogTag* tag in post.tags ) {
            tag.handle = tag.name.URLFriendlyHandle;
            [realm addOrUpdateObject:tag];
        }

        [realm addOrUpdateObject:post];
        if ( [realm commitWriteTransaction:&error] ) {
            [CWAPIController succeedWithPayload:post.modelObject.toDictionary request:request response:response];
        } else {
            [CWAPIController failWithError:error request:request response:response];
        }

    };
}

- (CRRouteBlock)relatedPostsBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* pid = request.query[@"pid"];

        CWBlogPost* post = [CWBlogPost getByUID:pid];
        if (post == nil) {
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
    };
}

#pragma mark - Tags

- (CRRouteBlock)getTagBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* tid = request.query[@"tid"];

        CWBlogTag* tag = [CWBlogTag getByUID:tid];
        if (tag != nil) {
            [CWAPIController succeedWithPayload:tag.modelObject.toDictionary request:request response:response];
        } else {
            [response setStatusCode:404 description:nil];
            [CWAPIController failWithError:nil request:request response:response];
        }
    };
}

- (CRRouteBlock)deleteTagBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSError *error = [NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorNotImplemented userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Not implemented",)}];
        [CWAPIController failWithError:error request:request response:response];
    };
}

- (CRRouteBlock)createOrUpdateTagBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

        NSError* error = nil;
        CWAPIBlogTag* receivedTag = [[CWAPIBlogTag alloc] initWithDictionary:request.body error:&error];
        if ( error ) {
            [CWAPIController failWithError:error request:request response:response];
            return;
        }

        RLMRealm *realm = [CWBlog realm];
        [realm beginWriteTransaction];

        CWBlogTag* tag = (CWBlogTag *)receivedTag.schemaObject;
        tag.handle = tag.name.URLFriendlyHandle;

        [realm addOrUpdateObject:tag];
        if ( [realm commitWriteTransaction:&error] ) {
            [CWAPIController succeedWithPayload:tag.modelObject.toDictionary request:request response:response];
        } else {
            [CWAPIController failWithError:error request:request response:response];
        }
        
    };
}

- (CRRouteBlock)searchTagsBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* q = request.query[@"q"];

        RLMResults* tags = [[CWBlogTag getObjectsWhere:@"name contains[c] %@", q] sortedResultsUsingProperty:@"name" ascending:YES];
        NSMutableArray* result = [NSMutableArray array];
        for ( CWBlogTag* tag in tags ) {
            [result addObject:tag.modelObject.toDictionary];
        }

        [CWAPIController succeedWithPayload:result request:request response:response];
    };
}

@end
