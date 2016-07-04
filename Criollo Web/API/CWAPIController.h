//
//  CWAPIController.h
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Criollo/Criollo.h>

#define CWUserCookie            @"cwuser"
#define CWAPIUsernameKey         @"username"
#define CWAPIPasswordKey        @"password"

@class CWUser;

NS_ASSUME_NONNULL_BEGIN

@interface CWAPIController : NSObject

+ (CWAPIController *)sharedController;
- (CRRouteBlock)routeBlock;

@end

NS_ASSUME_NONNULL_END