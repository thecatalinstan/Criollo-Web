//
//  CWAPIController.h
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Foundation/Foundation.h>
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

+ (CWAPIController *)sharedController;

@end

NS_ASSUME_NONNULL_END