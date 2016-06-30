//
//  CWAPIController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWAPIController.h"
#import "CWAPIError.h"
#import "CWAPIResponse.h"
#import "CWAppDelegate.h"
#import "CWUser.h"

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
        if ( [predicate isEqualToString:@"login"] ) {
            self.authenticateBlock(request, response, completionHandler);
        } else if ( [predicate isEqualToString:@"logout"] ) {
            self.deauthenticateBlock(request, response, completionHandler);
        } else {
            [response sendData:[CWAPIResponse successResponseWithData:nil].toJSONData];
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
            user = [CWUser authenticateWithUsername:credentials[CWAPIUsrnameKey] password:credentials[CWAPIPasswordKey]];
        }

        if ( !user ) {
            [response setStatusCode:401 description:nil];
            [response setCookie:CWUserCookie value:@"" path:@"/" expires:[NSDate distantPast] domain:nil secure:NO];
            apiResponse = [CWAPIResponse failureResponseWithError:[NSError errorWithDomain:CWAPIErrorDomain code:CWAPIErrorLoginFailed userInfo:@{NSLocalizedDescriptionKey: @"Invalid username or password"}]];
        } else {
            [response setStatusCode:200 description:nil];
            [response setCookie:CWUserCookie value:user.username path:@"/" expires:nil domain:nil secure:NO];
            apiResponse = [CWAPIResponse successResponseWithData:user];
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
        [response setCookie:CWUserCookie value:@"" path:@"/" expires:[NSDate distantPast] domain:nil secure:NO];
        [response setValue:@(responseData.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendData:responseData];
    };
}


@end
