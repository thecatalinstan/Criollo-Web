//
//  CWBlogAuthor.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWSchema.h"

@interface CWBlogAuthor : CWSchema

@property (nullable) NSString * user;
@property (nullable) NSString * displayName;
@property (nullable) NSString * email;

+ (nullable instancetype)getByUser:(NSString * _Nonnull)username;

@end