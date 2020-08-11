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
#import "CWAppDelegate.h"
#import "NSString+MD5.h"

@implementation CWUser

static NSArray<CWUser *> *allUsers;

+ (void)initialize {
    if (self != CWUser.class) {
        return;
    }
        
    [self updateUsers];
}

+ (void)updateUsers {
    NSError *error;

    NSData *data;
    if (!(data = [[NSData alloc] initWithContentsOfURL:[CWAppDelegate.baseDirectory URLByAppendingPathComponent:@"users.json"] options:NSDataReadingUncached error:&error])) {
        [CRApp logErrorFormat:@"%@ Error opening users file. %@", [NSDate date], error];
        return;
    }
    
    NSArray<CWUser *> *users;
    if (!(users = [CWUser arrayOfModelsFromData:data error:&error])) {
        [CRApp logErrorFormat:@"%@ Error parsing users file. %@", [NSDate date], error];
        return;
    }
    
    for (CWUser *user in users) {
        user.tokenHash = [NSString stringWithFormat:@"%@%@%@", user.email, user.password, user.username].MD5Stirng;
    }
    
    @synchronized (allUsers) {
        allUsers = users;
    }
}

+ (NSArray<CWUser *> *)allUsers {
    @synchronized (allUsers) {
        return allUsers;
    }
}

+ (CWUser *)authenticateWithUsername:(NSString *)username password:(NSString *)password {
    if (username.length == 0 || password.length == 0) {
        return nil;
    }
    
    for (CWUser *user in CWUser.allUsers) {
        if ([user.username isEqualToString:username] && [user.password isEqualToString:password]) {
            return user;
        }
    }
    
    return nil;
}


+ (NSString *)authenticationTokenForUser:(CWUser *)user {
    if (!user) {
        return nil;
    }

    NSString* password = [CSSystemInfoHelper sharedHelper].platformUUID;
    return [JWTBuilder encodePayload:@{@"token":user.tokenHash}].secret(password).algorithmName(@"HS256").encode;
}

+ (NSDictionary *)debugLoginInfo:(NSString *)token{
    NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithCapacity:2];
    payload[@"token"] = token;
    payload[@"user"] = [CWUser authenticatedUserForToken:token].toDictionary.mutableCopy;
    [(NSMutableDictionary *)payload[@"user"] removeObjectForKey:@"password"];
    return payload;
}

+ (CWUser *)authenticatedUserForToken:(NSString *)token {
    if (token.length == 0) {
        return nil;
    }

    NSString* password = CSSystemInfoHelper.sharedHelper.platformUUID;
    NSString* plainTextTokenHash = [JWTBuilder decodeMessage:token].secret(password).algorithmName(@"HS256").decode[@"payload"][@"token"];
    
    for (CWUser *user in CWUser.allUsers) {
        if ([user.tokenHash  isEqualToString:plainTextTokenHash]) {
            return user;
        }
    }
    
    return nil;
}


@end
