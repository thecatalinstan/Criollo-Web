//
//  CWSchema.h
//  Criollo Web
//
//  Created by Cătălin Stan on 27/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Realm/Realm.h>
#import "CWModelProxy.h"

@class CRRequest;

NS_ASSUME_NONNULL_BEGIN

@interface CWSchema : RLMObject<CWModelProxy>

@property NSString * uid;
@property NSString * handle;

@property (nonatomic, readonly, strong) NSString * publicPath;

+ (nullable instancetype)getSingleObjectWhere:(NSString *)predicateFormat, ...;
+ (nullable instancetype)getSingleObjectWhere:(NSString *)predicateFormat args:(va_list)args;
+ (nullable instancetype)getSingleObjectWithPredicate:(NSPredicate *)predicate;

+ (nonnull RLMResults *)getObjectsWhere:(NSString *)predicateFormat, ...;
+ (nonnull RLMResults *)getObjectsWhere:(NSString *)predicateFormat args:(va_list)args;
+ (nonnull RLMResults *)getObjectsWithPredicate:(NSPredicate *)predicate;

+ (nullable instancetype)getByUID:(NSString *)uid;
+ (nullable instancetype)getByHandle:(NSString *)handle;

- (NSString *)permalinkForRequest:(CRRequest *)request;

@end

NS_ASSUME_NONNULL_END
