//
//  CWBlogPost.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CWBlogAuthor, CWBlogTag, CWAPIBlogPost;

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogPost : NSManagedObject

@property (nonatomic, readonly, strong) NSString * path;
@property (nonatomic, readonly, copy) CWAPIBlogPost* APIBlogPost;

+ (instancetype)blogPostWithHandle:(NSString *)handle;
+ (instancetype)blogPostWithHandle:(NSString *)handle year:(NSUInteger)year;
+ (instancetype)blogPostWithHandle:(NSString *)handle year:(NSUInteger)year month:(NSUInteger)month;

+ (nullable NSArray<CWBlogPost *> *)fetchBlogPostsWithPredicate:(NSPredicate * _Nullable)predicate error:(NSError * _Nullable __autoreleasing * _Nullable)error;

+ (instancetype)blogPostFromAPIBlogPost:(CWAPIBlogPost *)post;


@end

NS_ASSUME_NONNULL_END

#import "CWBlogPost+CoreDataProperties.h"
