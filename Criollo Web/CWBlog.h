//
//  CWBlog.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define CWBlogErrorDomain           @"CWBlogErrorDomain"
#define CWBlogError                 101

#define CWBlogPath                  @"/blog"
#define CWBlogNewPostPath           @"/new"
#define CWBlogArchivePath           @"/archive"
#define CWBlogTagPath               @"/tag"
#define CWBlogAuthorPath            @"/author"
#define CWBlogSinglePostPath        @"/:year/:month/:handle"
#define CWBlogEditPostPath          @"/:year/:month/:handle/edit"

typedef struct {
    NSUInteger year;
    NSUInteger month;
} CWBlogArchivePeriod;

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogDatePair : NSObject

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@end

@interface CWBlog : NSObject

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (readonly, strong, nonatomic) NSURL *baseDirectory;

- (instancetype)initWithBaseDirectory:(NSURL *)baseDirectory error:(NSError * __autoreleasing *)error;
- (BOOL)saveManagedObjectContext:(NSError * __autoreleasing *)error;
- (BOOL)importUsersFromDefaults:(NSError * __autoreleasing *)error;

+ (NSString *)formattedDate:(NSDate *)date;
+ (NSString *)formattedTime:(NSDate *)date;

+ (CWBlogArchivePeriod)parseYear:(NSUInteger)year month:(NSUInteger)month;
+ (CWBlogDatePair *)datePairWithYearMonth:(CWBlogArchivePeriod)period;

@end

NS_ASSUME_NONNULL_END