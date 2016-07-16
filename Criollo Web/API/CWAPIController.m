//
//  CWAPIController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <CSSystemInfoHelper/CSSystemInfoHelper.h>
#import <MMMarkdown/MMMarkdown.h>

#import "CWAPIController.h"
#import "CWAPIError.h"
#import "CWAPIResponse.h"
#import "CWAppDelegate.h"
#import "CWUser.h"
#import "CWAPIBlogTag.h"
#import "CWAPIBlogAuthor.h"
#import "CWAPIBlogPost.h"
#import "CWBlogTag.h"
#import "CWBlogAuthor.h"
#import "CWBlogPost.h"
#import "CWAppDelegate.h"
#import "CWBlog.h"
#import "NSString+URLUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWAPIController ()

@property (nonatomic, strong, readonly) dispatch_queue_t isolationQueue;

- (CRRouteBlock)authenticateBlock;
- (CRRouteBlock)deauthenticateBlock;

- (void)succeedWithPayload:(id _Nullable)payload request:(CRRequest *)request response:(CRResponse *)response;
- (void)failWithError:(NSError * _Nullable)error request:(CRRequest *)request response:(CRResponse *)response;

@end

NS_ASSUME_NONNULL_END

@implementation CWAPIController

+ (CWAPIController *)sharedController {
    static CWAPIController* sharedController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[CWAPIController alloc] init];
    });
    return sharedController;
}

- (dispatch_queue_t)isolationQueue {
    static dispatch_queue_t isolationQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isolationQueue = dispatch_queue_create([[NSStringFromClass(self.class) stringByAppendingPathExtension:@"IsolationQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(isolationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    });
    return isolationQueue;
}

#pragma mark - API

- (void)succeedWithPayload:(id)payload request:(CRRequest *)request response:(CRResponse *)response {
    CWAPIResponse * apiResponse = [CWAPIResponse successResponseWithData:payload];
    NSData * jsonData = [apiResponse toJSONData];

    [response setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-type"];
    [response setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonData.length] forHTTPHeaderField:@"Content-length"];
    [response sendData:jsonData];
}

- (void)failWithError:(NSError*)error request:(CRRequest *)request response:(CRResponse *)response {
    CWAPIResponse * apiResponse = [CWAPIResponse failureResponseWithError:error];
    NSData * jsonData = [apiResponse toJSONData];

    [response setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-type"];
    [response setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonData.length] forHTTPHeaderField:@"Content-length"];
    [response sendData:jsonData];
}

#pragma mark - Routes

- (CRRouteBlock)routeBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        NSString* predicate = request.URL.pathComponents.count > 2 ? request.URL.pathComponents[2] : @"";

        // Login / Logout
        if ( [predicate isEqualToString:@"login"] ) {
            self.authenticateBlock(request, response, completionHandler);
        } else if ( [predicate isEqualToString:@"logout"] ) {
            self.deauthenticateBlock(request, response, completionHandler);
        } else if ( [predicate isEqualToString:@"me"] ) {
            self.meBlock(request, response, completionHandler);
        } else if ( [predicate isEqualToString:@"trace"] ) {
            [response sendData:[CWAPIResponse successResponseWithData:[NSThread callStackSymbols]].toJSONData];
        } else if ( [predicate isEqualToString:@"info"] ) {
            self.infoBlock(request, response, completionHandler);
        } else if ( [predicate isEqualToString:@"blog"] ) {
            self.blogBlock(request, response, completionHandler);
        } else {
            [response sendData:[CWAPIResponse successResponseWithData:request.cookies[CWUserCookie]].toJSONData];
            completionHandler();
        }
    };
}

- (CRRouteBlock)authenticateBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CWUser * user;
        CWAPIResponse * apiResponse;

        NSDictionary<NSString *, NSString *>* credentials = (NSDictionary *)request.body;
        if ( credentials ) {
            user = [CWUser authenticateWithUsername:credentials[CWAPIUsernameKey] password:credentials[CWAPIPasswordKey]];
        }

        if ( !user ) {
            [response setStatusCode:401 description:nil];
            [response setCookie:CWUserCookie value:@"" path:@"/" expires:[NSDate distantPast] domain:nil secure:NO];
            apiResponse = [CWAPIResponse failureResponseWithError:[NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorLoginFailed userInfo:@{NSLocalizedDescriptionKey: @"Invalid username or password"}]];
        } else {
            [response setStatusCode:200 description:nil];

            NSMutableDictionary* payload = user.toDictionary.mutableCopy;
            [payload removeObjectForKey:@"password"];
            apiResponse = [CWAPIResponse successResponseWithData:payload];

            NSString *token = [CWUser authenticationTokenForUser:user];
            [response setCookie:CWUserCookie value:token path:@"/" expires:nil domain:nil secure:NO];
        }

        NSData * responseData = apiResponse.toJSONData;
        [response setValue:@(responseData.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendData:responseData];
    };
}

- (CRRouteBlock)deauthenticateBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CWAPIResponse * apiResponse = [CWAPIResponse successResponseWithData:nil];
        NSData * responseData = apiResponse.toJSONData;
        [response setCookie:CWUserCookie value:@"deleted" path:@"/" expires:[NSDate distantPast] domain:nil secure:NO];
        [response setValue:@(responseData.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendData:responseData];
    };
}

- (CRRouteBlock)meBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CWUser * currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
        CWAPIResponse * apiResponse;
        if ( currentUser ) {
            NSMutableDictionary* payload = currentUser.toDictionary.mutableCopy;
            [payload removeObjectForKey:@"password"];
            apiResponse = [CWAPIResponse successResponseWithData:payload];
        } else {
            [response setStatusCode:401 description:nil];
            apiResponse = [CWAPIResponse failureResponseWithError:nil];
        }
        [response sendData:apiResponse.toJSONData];
        completionHandler();
    };
}

- (CRRouteBlock)infoBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSMutableDictionary* payload = [NSMutableDictionary dictionary];

        payload[@"processName"] = [CWAppDelegate processName];
        payload[@"processVersion"] = [CWAppDelegate bundleVersion];
        payload[@"runningTime"] = [CWAppDelegate processRunningTime];
        payload[@"unameSystemVersion"] = [CSSystemInfoHelper sharedHelper].systemVersionString;
        payload[@"requestsServed"] = [CWAppDelegate requestsServed];

        payload[@"memoryInfo"] = [CSSystemInfoHelper sharedHelper].memoryUsageString ? : @"";
        [response sendData:[CWAPIResponse successResponseWithData:payload].toJSONData];
        completionHandler();
    };
}

- (CRRouteBlock)blogBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* payload = request.URL.pathComponents.count > 3 ? request.URL.pathComponents[3] : @"";
        if ( [payload isEqualToString:@"posts"]) {
            switch(request.method) {
                case CRHTTPMethodPut: {
                    __block BOOL shouldFail = NO;
                    __block NSError* error;
                    __block CWBlogPost* post;
                    __block CWAPIBlogPost* responsePost;
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
                                if ( currentUser ) {
                                    post.author = [CWBlogAuthor fetchAuthorForUsername:currentUser.username error:nil];
                                }

                                error = nil;
                                [[CWAppDelegate sharedBlog] saveManagedObjectContext:&error];
                                shouldFail = error == nil;
                                if ( !error ) {
                                    responsePost = post.APIBlogPost;
                                }
                            }];
                        }
                    }

                    if ( shouldFail ) {
                        [response setStatusCode:500 description:nil];
                        [response sendData:[CWAPIResponse failureResponseWithError:error].toJSONData];
                    } else {
                        [response sendData:[CWAPIResponse successResponseWithData:responsePost].toJSONData];
                    }
                    completionHandler();
                }
                    break;
                default:
                    break;
            }
        }
    };
}

@end
