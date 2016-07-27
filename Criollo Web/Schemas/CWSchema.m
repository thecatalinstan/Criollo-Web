//
//  CWSchema.m
//  Criollo Web
//
//  Created by Cătălin Stan on 27/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWSchema.h"
#import "CWAppDelegate.h"
#import "CWBlog.h"
#import "CWModel.h"

@implementation CWSchema

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
    return @[@"publicPath"];
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
    RLMResults* results = [[self class] objectsInRealm:[CWAppDelegate sharedBlog].realm where:predicateFormat args:args];
    va_end(args);
    if (results.count == 0) {
        return nil;
    }
    return results.firstObject;
}

+ (RLMResults *)getObjectsWhere:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    RLMResults* results = [[self class] objectsInRealm:[CWAppDelegate sharedBlog].realm where:predicateFormat args:args];
    va_end(args);
    return results;
}

+ (instancetype)getByUID:(NSString *)uid {
    return [[self class] getSingleObjectWhere:@"uid = %@", uid];
}

+ (instancetype)getByHandle:(NSString *)handle {
    return [[self class] getSingleObjectWhere:@"handle = %@", handle];
}

@end
