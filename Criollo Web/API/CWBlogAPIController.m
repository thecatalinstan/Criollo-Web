//
//  CWBlogAPIController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 21/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogAPIController.h"
#import "CWAppDelegate.h"
#import "CWAPIController.h"
#import "CWBlogImageController.h"

#import "CWAPIError.h"
#import "CWUser.h"
#import "CWBlog.h"
#import "NSString+URLUtils.h"

#import "CWAPIBlogTag.h"
#import "CWAPIBlogAuthor.h"
#import "CWAPIBlogPost.h"
#import "CWAPIBlogImage.h"

#import "CWBlogTag.h"
#import "CWBlogAuthor.h"
#import "CWBlogPost.h"
#import "CWBlogImage.h"

#define CWBlogAPIPostsPath              @"/posts"
#define CWBlogAPISinglePostPath         @"/posts/:pid"
#define CWBlogAPIRelatedPostsPath       @"/related/:pid"

#define CWBlogAPITagsPath               @"/tags"
#define CWBlogAPISearchTagsPath         @"/tags/search"
#define CWBlogAPISingleTagPath          @"/tags/:tid"

#define CWBlogAPIImagesPath             @"/images"
#define CWBlogAPISingleImagePath        @"/images/:iid"

#define CWBlogAPIMakeHandlePath         @"/make-handle"

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
        
        CWBlogImage *image;
        if (receivedPost.image.uid.length) {
            if (!(image = [CWBlogImage getByUID:receivedPost.image.uid])) {
                error = [NSError errorWithDomain:CWBlogErrorDomain code:CWBlogUnknownImage userInfo:nil];
                [CWAPIController failWithError:error request:request response:response];
                return;
            }
        }
                
        RLMRealm *realm = [CWBlog realm];
        
        [realm beginWriteTransaction];
        
        // Save the current image uid
        CWBlogImage *previousImage = [CWBlogPost getByUID:receivedPost.uid].image;
        
        // Update the post
        CWBlogPost *post = (CWBlogPost *)receivedPost.schemaObject;
        post.renderedContent = renderedContent;
        post.excerpt = excerpt;
        post.author = author;
        post.image = image;
        post.lastUpdatedDate = [NSDate date];
        if (!post.publishedDate) {
            post.publishedDate = [NSDate date];
        }
        if (!post.handle.length) {
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
        
        // Delete the old image and its representations
        if (previousImage) {
            NSString *uid = previousImage.uid, *publicPath = previousImage.publicPath;
            NSArray<CWImageSizeRepresentation *> *representations = previousImage.sizeRepresentations;
            
            [realm beginWriteTransaction];
            [realm deleteObject:previousImage];
            if (![realm commitWriteTransaction:&error]) {
                [CRApp logErrorFormat:@"%@ Unable to delete image %@. %@", NSDate.date, uid, error.localizedDescription];
            } else if (![CWBlogImageController.sharedController deleteImageAtPublicPath:publicPath imageSizeRepresentations:representations error:&error]) {
                [CRApp logErrorFormat:@"%@ Unable to delete image files %@. %@", NSDate.date, publicPath, error.localizedDescription];
            }
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

    // Get single tag
    [self get:CWBlogAPISingleTagPath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString *tid = request.query[@"tid"];
        
        CWBlogTag *tag;
        if (!(tag = [CWBlogTag getByUID:tid])) {
            [response setStatusCode:404 description:nil];
            NSError *error = [NSError errorWithDomain:CWBlogErrorDomain code:CWBlogUnknownTag userInfo:nil];
            [CWAPIController failWithError:error request:request response:response];
            return;
        }
        [CWAPIController succeedWithPayload:tag.modelObject.toDictionary request:request response:response];
    }}];

    // Delete single tag
    [self delete:CWBlogAPISingleTagPath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSError *error = [NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorNotImplemented userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Not implemented",)}];
        [CWAPIController failWithError:error request:request response:response];
    }}];

    // Create/update single tag
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
    
    // Get single image
    [self get:CWBlogAPISingleImagePath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString *iid = request.query[@"iid"];
        
        CWBlogImage *image;
        if (!(image = [CWBlogImage getByUID:iid])) {
            [response setStatusCode:404 description:nil];
            NSError *error = [NSError errorWithDomain:CWBlogErrorDomain code:CWBlogUnknownImage userInfo:nil];
            [CWAPIController failWithError:error request:request response:response];
            return;
        }
        [CWAPIController succeedWithPayload:image.modelObject.toDictionary request:request response:response];
    }}];
    
    [self post:CWBlogAPISingleImagePath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString *iid = request.query[@"iid"];
        
        CWBlogImage *image;
        if (!(image = [CWBlogImage getByUID:iid])) {
            [response setStatusCode:404 description:nil];
            NSError *error = [NSError errorWithDomain:CWBlogErrorDomain code:CWBlogUnknownImage userInfo:nil];
            [CWAPIController failWithError:error request:request response:response];
            return;
        }
        
        NSError *error;
        if (![CWBlogImageController.sharedController preocessUploadedFile:request.files.allValues.firstObject publicPath:image.publicPath imageSizeRepresentations:image.sizeRepresentations error:&error]) {
            [response setStatusCode:500 description:nil];
            [CWAPIController failWithError:error request:request response:response];
            return;
        }
        
        [CWAPIController succeedWithPayload:image.modelObject.toDictionary request:request response:response];
    }];

    // Delete single image
    [self delete:CWBlogAPISingleImagePath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSError *error = [NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorNotImplemented userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Not implemented",)}];
        [CWAPIController failWithError:error request:request response:response];
    }}];

    // Create/update single image
    CRRouteBlock createOrUpdateImageBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSError* error;
        CWAPIBlogImage *receivedImage;
        if (!(receivedImage = [[CWAPIBlogImage alloc] initWithDictionary:request.body error:&error])) {
            [CWAPIController failWithError:error request:request response:response];
            return;
        }
        
        RLMRealm *realm = [CWBlog realm];
        [realm beginWriteTransaction];
        
        CWBlogImage *image = (CWBlogImage *)receivedImage.schemaObject;
        if (!image.handle) {
            image.handle = NSString.randomURLFriendlyHandle;
        }
        
        [realm addOrUpdateObject:image];
        if (![realm commitWriteTransaction:&error]) {
            [CWAPIController failWithError:error request:request response:response];
        }

        [CWAPIController succeedWithPayload:image.modelObject.toDictionary request:request response:response];
//        [[NSNotificationCenter defaultCenter] postNotificationName:CWRoutesChangedNotificationName object:nil];
    }};
    [self put:CWBlogAPIImagesPath block:createOrUpdateImageBlock];
    [self post:CWBlogAPIImagesPath block:createOrUpdateImageBlock];
    
    [self get:CWBlogAPIImagesPath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        RLMRealm *realm = [CWBlog realm];
        RLMResults<CWBlogImage *> *images = [CWBlogImage allObjectsInRealm:realm];
        NSMutableArray<NSDictionary *> *result = [NSMutableArray arrayWithCapacity:images.count];
        for (CWBlogImage *image in images) {
            [result addObject:image.modelObject.toDictionary];
        }
        
        [CWAPIController succeedWithPayload:result request:request response:response];
    }];
}

@end
