//
//  CWUser.m
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

#import "CWUser.h"

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

@end
