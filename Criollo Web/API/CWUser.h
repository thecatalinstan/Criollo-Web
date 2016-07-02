//
//  CWUser.h
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWModel.h"

#define CWDefaultsUsersKey      @"Users"

NS_ASSUME_NONNULL_BEGIN

@interface CWUser : CWModel

@property (nonatomic, strong) NSString * username;
@property (nonatomic, strong) NSString * password;
@property (nonatomic, strong, nullable) NSString<Optional> * firstName;
@property (nonatomic, strong, nullable) NSString<Optional> * lastName;
@property (nonatomic, strong) NSString * email;
@property (nonatomic, strong) NSString<Ignore> * tokenHash;

+ (NSDictionary<NSString *, CWUser *> *)allUsers;

+ (nullable CWUser *)authenticateWithUsername:(NSString * _Nullable)username password:(NSString * _Nullable)password;

+ (NSString *)authenticationTokenForUser:(CWUser *)user;
+ (CWUser *)authenticatedUserForToken:(NSString *)token;

@end

NS_ASSUME_NONNULL_END