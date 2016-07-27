//
//  CWSchema.h
//  Criollo Web
//
//  Created by Cătălin Stan on 27/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Realm/Realm.h>
#import "CWModelProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWSchema : RLMObject<CWModelProxy>

@property NSString * uid;
@property NSString * handle;

@property (nonatomic, readonly, strong) NSString * publicPath;

+ (nullable instancetype)getSingleObjectWhere:(NSString *)predicateFormat, ...;
+ (nonnull RLMResults *)getObjectsWhere:(NSString *)predicateFormat, ...;

+ (nullable instancetype)getByUID:(NSString *)uid;
+ (nullable instancetype)getByHandle:(NSString *)handle;

@end

NS_ASSUME_NONNULL_END
