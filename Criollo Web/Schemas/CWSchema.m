//
//  CWSchema.m
//  Criollo Web
//
//  Created by Cătălin Stan on 27/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

#import "CWSchema.h"
#import "CWBlog.h"
#import "CWModel.h"
#import "CWAppDelegate.h"

@implementation CWSchema

- (NSString *)permalinkForRequest:(CRRequest *)request {
    return [NSURL URLWithString:self.publicPath relativeToURL:[CWAppDelegate baseURL]].absoluteString;
}

#pragma mark - Realm

+ (NSArray<NSString *> *)indexedProperties {
    return @[@"uid", @"handle"];
}

+ (nullable NSDictionary *)defaultPropertyValues {
    return @{ @"uid": [NSUUID UUID].UUIDString };
}

+ (nullable NSString *)primaryKey {
    return @"uid";
}

+ (NSArray<NSString *> *)requiredProperties {
    return @[@"uid"];
}

+ (nullable NSArray<NSString *> *)ignoredProperties {
    return @[@"publicPath", @"permalink"];
}

#pragma mark - API

- (NSString *)publicPath {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ must be overriden in a subclass", NSStringFromSelector(_cmd)] userInfo:nil];
}

#pragma mark - CWModelProxy

- (CWModel *)modelObject {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ must be overriden in a subclass", NSStringFromSelector(_cmd)] userInfo:nil];
}

#pragma mark - Fetching

+ (instancetype)getSingleObjectWhere:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    CWSchema *result = [[self class] getSingleObjectWhere:predicateFormat args:args];
    va_end(args);
    return result;
}

+ (instancetype)getSingleObjectWhere:(NSString *)predicateFormat args:(va_list)args {
    return [[self class] getSingleObjectWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

+ (instancetype)getSingleObjectWithPredicate:(NSPredicate *)predicate {
    RLMResults *results = [[self class] getObjectsWithPredicate:predicate];
    if ( results.count == 0 ) {
        return nil;
    }
    return results.firstObject;
}

+ (RLMResults *)getObjectsWhere:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    RLMResults *results = [[self class] getObjectsWhere:predicateFormat args:args];
    va_end(args);
    return results;
}

+ (RLMResults *)getObjectsWhere:(NSString *)predicateFormat args:(va_list)args {
    return [[self class] getObjectsWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

+ (RLMResults *)getObjectsWithPredicate:(NSPredicate *)predicate {
    RLMRealm * realm = [CWBlog realm];
    return [[self class] objectsInRealm:realm withPredicate:predicate];
}

+ (instancetype)getByUID:(NSString *)uid {
    return [[self class] getSingleObjectWhere:@"uid = %@", uid];
}

+ (instancetype)getByHandle:(NSString *)handle {
    return [[self class] getSingleObjectWhere:@"handle = %@", handle];
}

@end
