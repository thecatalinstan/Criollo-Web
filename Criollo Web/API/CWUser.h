//
//  CWUser.h
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWModel.h"

NS_ASSUME_NONNULL_BEGIN
@interface CWUser : CWModel

@property (nonatomic, strong) NSString * username;
@property (nonatomic, strong) NSString * password;
@property (nonatomic, strong, nullable) NSString<Optional> * firstName;
@property (nonatomic, strong, nullable) NSString<Optional> * lastName;
@property (nonatomic, strong) NSString * email;

@end
NS_ASSUME_NONNULL_END