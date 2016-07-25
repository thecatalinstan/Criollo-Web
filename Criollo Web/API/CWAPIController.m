//
//  CWAPIController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <CSSystemInfoHelper/CSSystemInfoHelper.h>

#import "CWAPIController.h"
#import "CWAPIError.h"
#import "CWAPIResponse.h"
#import "CWAppDelegate.h"
#import "CWUser.h"
#import "CWBlogAPIController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWAPIController ()

@property (nonatomic, strong, readonly) dispatch_queue_t isolationQueue;

- (void)setupRoutes;

@end

NS_ASSUME_NONNULL_END

@implementation CWAPIController

+ (instancetype)sharedController {
    static CWAPIController* sharedController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[CWAPIController alloc] initWithPrefix:CWAPIPath];
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

#pragma mark - API Response Wrappers

+ (void)succeedWithPayload:(id)payload request:(CRRequest *)request response:(CRResponse *)response {
    CWAPIResponse * apiResponse = [CWAPIResponse successResponseWithData:payload];
    NSData * jsonData = [apiResponse toJSONData];

    [response setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonData.length] forHTTPHeaderField:@"Content-length"];
    [response sendData:jsonData];
}

+ (void)failWithError:(NSError*)error request:(CRRequest *)request response:(CRResponse *)response {
    CWAPIResponse * apiResponse = [CWAPIResponse failureResponseWithError:error];
    NSData * jsonData = [apiResponse toJSONData];

    [response setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonData.length] forHTTPHeaderField:@"Content-length"];
    [response sendData:jsonData];
}

#pragma mark - Routing

- (void)setupRoutes {

    // Set content-type to JSON
    [self addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        completionHandler();
    }];

    // Default route
    [self add:@"/" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [CWAPIController succeedWithPayload:request.cookies[CWUserCookie] request:request response:response];
        completionHandler();
    }];

    // Login
    [self post:CWAPILoginPath block:self.authenticateBlock];

    // Logout
    [self get:CWAPILogoutPath block:self.deauthenticateBlock];

    // Currently authneticated user
    [self get:CWAPIMePath block:self.meBlock];

    // Simple stack trace
    [self get:CWAPITracePath block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response sendData:[CWAPIResponse successResponseWithData:[NSThread callStackSymbols]].toJSONData];
        completionHandler();
    }];

    // Info
    [self get:CWAPIInfoPath block:self.infoBlock];

    // Blog
    [self add:CWAPIBlogPath block:self.checkAuthBlock recursive:YES];
    [self add:CWAPIBlogPath block:[CWBlogAPIController sharedController].routeBlock recursive:YES];

    // Finish the response
}

#pragma mark - Authentication

- (CRRouteBlock)authenticateBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CWUser * user;

        NSDictionary<NSString *, NSString *>* credentials = (NSDictionary *)request.body;
        if ( credentials ) {
            user = [CWUser authenticateWithUsername:credentials[CWAPIUsernameKey] password:credentials[CWAPIPasswordKey]];
        }

        if ( !user ) {
            [response setStatusCode:401 description:nil];
            [response setCookie:CWUserCookie value:@"deleted" path:@"/" expires:[NSDate distantPast] domain:nil secure:NO];
            [CWAPIController failWithError:[NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorLoginFailed userInfo:@{NSLocalizedDescriptionKey: @"Invalid username or password"}] request:request response:response];
        } else {
            [response setStatusCode:200 description:nil];

            NSString *token = [CWUser authenticationTokenForUser:user];
            [response setCookie:CWUserCookie value:token path:@"/" expires:nil domain:nil secure:NO];

            NSMutableDictionary* payload = user.toDictionary.mutableCopy;
            [payload removeObjectForKey:@"password"];

            [CWAPIController succeedWithPayload:payload request:request response:response];
        }

        completionHandler();
    };
}

- (CRRouteBlock)deauthenticateBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setCookie:CWUserCookie value:@"deleted" path:@"/" expires:[NSDate distantPast] domain:nil secure:NO];
        [CWAPIController succeedWithPayload:nil request:request response:response];
        completionHandler();
    };
}

#pragma mark - Users

- (CRRouteBlock)meBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CWUser * currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
        if ( currentUser ) {
            NSMutableDictionary* payload = currentUser.toDictionary.mutableCopy;
            [payload removeObjectForKey:@"password"];
            [CWAPIController succeedWithPayload:payload request:request response:response];
        } else {
            [response setStatusCode:401 description:nil];
            NSError* error = [NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorUnauthorized userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"You are not authorized.",)}];
            [CWAPIController failWithError:error request:request response:response];
        }
        completionHandler();
    };
}

#pragma mark - Misc

- (CRRouteBlock)infoBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSMutableDictionary* payload = [NSMutableDictionary dictionary];
        payload[@"processName"] = [CWAppDelegate processName];
        payload[@"processVersion"] = [CWAppDelegate bundleVersion];
        payload[@"runningTime"] = [CWAppDelegate processRunningTime];
        payload[@"unameSystemVersion"] = [CSSystemInfoHelper sharedHelper].systemVersionString;
        payload[@"requestsServed"] = [CWAppDelegate requestsServed];
        payload[@"memoryInfo"] = [CSSystemInfoHelper sharedHelper].memoryUsageString ? : @"";
        [CWAPIController succeedWithPayload:payload request:request response:response];
        completionHandler();
    };
}

- (CRRouteBlock)checkAuthBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CWUser* currentUser = [CWUser authenticatedUserForToken:request.cookies[CWUserCookie]];
        if ( !currentUser ) {
            NSError* error = [NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorUnauthorized userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"You are not authorized.",)}];
            [CWAPIController failWithError:error request:request response:response];
        } else {
            completionHandler();
        }
    };
}

@end
