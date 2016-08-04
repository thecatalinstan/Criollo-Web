//
//  CWUser.m
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>
#import <CSSystemInfoHelper/CSSystemInfoHelper.h>
#import <JWT/JWT.h>

#import "CWUser.h"
#import "NSString+MD5.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWUser ()



@end

NS_ASSUME_NONNULL_END

@implementation CWUser

+ (NSDictionary<NSString *,CWUser *> *)allUsers {
    static NSDictionary<NSString *,CWUser *> * allUsers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSUserDefaults standardUserDefaults ] synchronize];
        NSArray<NSString *> * defaultsUsers = [[NSUserDefaults standardUserDefaults] arrayForKey:CWDefaultsUsersKey];
        NSMutableDictionary<NSString *,CWUser *> * users = [NSMutableDictionary dictionary];
        [defaultsUsers enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            JSONModelError * jsonModelError = nil;
            CWUser * user = [[CWUser alloc] initWithString:obj error:&jsonModelError];
            user.tokenHash = [NSString stringWithFormat:@"%@%@%@", user.email, user.password, user.username].MD5Stirng;

            if ( jsonModelError ) {
                [CRApp logErrorFormat:@"Error parsing user JSON: %@", jsonModelError];
            } else {
                users[user.username] = user;
            }
        }];
        allUsers = users.copy;
    });
    return allUsers;
}

+ (CWUser *)authenticateWithUsername:(NSString *)username password:(NSString *)password {
    CWUser * user = [CWUser allUsers][username ? : @""];
    if ( ![user.password isEqualToString:password] ) {
        user = nil;
    }
    return user;
}


+ (NSString *)authenticationTokenForUser:(CWUser *)user {
    if ( user == nil ) {
        return nil;
    }

    NSString* password = [CSSystemInfoHelper sharedHelper].platformUUID;
    return [JWTBuilder encodePayload:@{@"token":user.tokenHash}].secret(password).algorithmName(@"HS256").encode;
}

+ (CWUser *)authenticatedUserForToken:(NSString *)token {
    if ( token.length == 0 ) {
        return nil;
    }

    NSString* password = [CSSystemInfoHelper sharedHelper].platformUUID;
    NSString* plainTextTokenHash = [JWTBuilder decodeMessage:token].secret(password).algorithmName(@"HS256").decode[@"token"];
    CWUser* user = [[CWUser allUsers].allValues filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(CWUser * _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject.tokenHash isEqualToString:plainTextTokenHash];
    }]].firstObject;

    return user;
}

@end
