//
//  CWAPIController.h
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

#define CWAPIPath                   @"/api"

#define CWAPILoginPath              @"/login"
#define CWAPILogoutPath             @"/logout"
#define CWAPIMePath       		 	@"/me"
#define CWAPITracePath              @"/trace"
#define CWAPIInfoPath               @"/info"
#define CWAPIBlogPath               @"/blog"

#define CWUserCookie                @"cwuser"
#define CWAPIUsernameKey            @"username"
#define CWAPIPasswordKey            @"password"

NS_ASSUME_NONNULL_BEGIN

@interface CWAPIController : CRRouteController

+ (void)succeedWithPayload:(id _Nullable)payload request:(CRRequest *)request response:(CRResponse *)response;
+ (void)failWithError:(NSError * _Nullable)error request:(CRRequest *)request response:(CRResponse *)response;

@end

NS_ASSUME_NONNULL_END