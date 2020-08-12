//
//  CWBlog.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Realm/Realm.h>
#import "CWBlogPost.h"

#define CWBlogErrorDomain           @"CWBlogErrorDomain"
#define CWBlogUnknownAuthor         1001
#define CWBlogUnknownImage          1002
#define CWBlogUnknownTag            1003
#define CWBlogEmptyPostContent      1050
#define CWBlogTwitterError          1100
#define CWBlogUnknownError          1999

#define CWBlogPath                  @"/blog"
#define CWBlogNewPostPath           @"/new"
#define CWBlogArchivePath           @"/archive"
#define CWBlogTagPath               @"/tag"
#define CWBlogImagePath             @"/image"
#define CWBlogAuthorPath            @"/author"
#define CWBlogFeedPath              @"/feed"
#define CWBlogArchiveYearPath       @"/[0-9]{4}"
#define CWBlogArchiveYearMonthPath  @"/[0-9]{4}/[0-9]{1,2}"
#define CWBlogSinglePostPath        @"/[0-9]{4}/[0-9]{1,2}/[\\w-]+"
#define CWBlogEditPostPath          @"/[0-9]{4}/[0-9]{1,2}/[\\w-]+/edit"

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

- (BOOL)updateAuthors:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)fetchTwitterInfo:(NSError * _Nullable __autoreleasing * _Nullable)error;

+ (RLMRealmConfiguration *)realmConfiguration;
+ (nullable RLMRealm *)realm;

+ (NSString *)formattedDate:(NSDate *)date;
+ (NSString *)formattedTime:(NSDate *)date;

+ (CWBlogArchivePeriod)parseYear:(NSUInteger)year month:(NSUInteger)month;
+ (CWBlogDatePair *)datePairArchivePeriod:(CWBlogArchivePeriod)period;
+ (CWBlogDatePair *)datePairWithYear:(NSUInteger)year month:(NSUInteger)month;

+ (nullable NSString *)renderMarkdown:(NSString *)markdownString error:(NSError * _Nullable __autoreleasing * _Nullable)error;
+ (nullable NSString *)excerptFromMarkdown:(NSString *)markdownString error:(NSError * _Nullable __autoreleasing * _Nullable)error;
+ (nullable NSString *)excerptFromHTML:(NSString *)htmlString error:(NSError * _Nullable __autoreleasing * _Nullable)error;

+ (NSArray<CWBlogPost *> *)relatedPostsForPost:(CWBlogPost *)post;
+ (NSArray<CWBlogPost *> *)relatedPostsForPost:(CWBlogPost *)post includeBlanks:(BOOL)flag;

+ (NSString *)stringByReplacingTwitterTokens:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
