//
//  CWAPIController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWAPIController.h"
#import "CWAppDelegate.h"

@interface CWAPIController ()

- (CRRouteBlock)authenticateBlock;
- (CRRouteBlock)deauthenticateBlock;

@end

@implementation CWAPIController

+ (CWAPIController *)sharedController {
    static CWAPIController* sharedController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[CWAPIController alloc] init];
    });
    return sharedController;
}

- (CRRouteBlock)routeBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        NSString* predicate = request.URL.pathComponents.count > 2 ? request.URL.pathComponents[2] : @"";
        if ( [predicate isEqualToString:@"login"] ) {
            self.authenticateBlock(request, response, completionHandler);
        } else if ( [predicate isEqualToString:@"logout"] ) {
            self.deauthenticateBlock(request, response, completionHandler);
        } else {
            [response finish];
            completionHandler();
        }
    };
}

- (CRRouteBlock)authenticateBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

        [response setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Encoding"];
        BOOL shouldFail = NO;
        NSDictionary<NSString *, NSString *>* sentCredentials = (NSDictionary *)request.body;

        if ( !sentCredentials ) {
            shouldFail = YES;
        } else {
            [[NSUserDefaults standardUserDefaults ] synchronize];
            NSDictionary * defaultsUsers = [[NSUserDefaults standardUserDefaults] dictionaryForKey:CWDefaultsUsersKey];
            if ( !defaultsUsers ) {
                shouldFail = YES;
            } else {
                NSString *password = defaultsUsers[sentCredentials[@"username"]];
                if ( ![password isEqualToString:sentCredentials[@"password"]] ) {
                    shouldFail  = YES;
                }
            }
        }

        if ( shouldFail ) {
            [response setStatusCode:401 description:nil];
            [response setCookie:CWUserCookie value:@"" path:@"/" expires:[NSDate distantPast] domain:nil secure:NO];
        } else {
            [response setStatusCode:200 description:nil];
            [response setCookie:CWUserCookie value:sentCredentials[@"username"] path:@"/" expires:nil domain:nil secure:NO];
        }
        [response setValue:@"0" forHTTPHeaderField:@"Content-Length"];
        [response finish];
    };
}

- (CRRouteBlock)deauthenticateBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Encoding"];
        [response setCookie:CWUserCookie value:@"" path:@"/" expires:[NSDate distantPast] domain:nil secure:NO];
        [response setValue:@"0" forHTTPHeaderField:@"Content-Length"];
        [response setValue:@"/" forHTTPHeaderField:@"Location"];
        [response finish];
    };
}


@end
